{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
module Lib where
import Control.Applicative ((<$>), optional)
import Data.Maybe (fromMaybe)
import Data.Text (Text, pack)
import Data.Text.Lazy (unpack, fromStrict)
import qualified Data.Text.Internal.Lazy as LT
import Happstack.Server
import Happstack.Server.SimpleHTTPS
import Control.Monad (when, msum, forM_)
import Control.Monad.IO.Class (liftIO)
import Text.Blaze.Html5 (Html, (!), a, form, input, p, toHtml, label)
import Text.Blaze.Html5.Attributes (action, enctype, href, name, size, type_, value)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import System.Directory hiding (findFile)
import System.Process
import Data.String
import Data.Hourglass
import Time.System (localDateCurrent)
import Network.Mail.SMTP hiding (Response)--
import           Crypto.Hash
import qualified Data.ByteString         as B
import           System.IO               (withBinaryFile, IOMode (ReadMode))


type Msg = String
type Adr = String

configFile = "config.conf"
logFile = "logger.txt"
confi2 = nullConf { port = 80 }
confi1 = nullTLSConf { tlsPort = 443
                     , tlsCert = "cert.pem" --"server101.mycloud.crt"
                     , tlsKey  =  "privkey.pem"--"server101.mycloud.key"
                     , tlsCA = Just "rootCA.crt"
                     }

formatTime = [ Format_Year4
             , Format_Text '-'
             , Format_Month2
             , Format_Text '-'
             , Format_Day2
             , Format_Text ' '
             , Format_Hour
             , Format_Text ':'
             , Format_Minute
             -- , Format_Text ':'
             -- , Format_Second
             ]

template :: Text -> Html -> Response
template title body = toResponse $
    H.html $ do
        H.head $ do
            H.title (toHtml title)
        H.body $ do
          body


hashFile :: FilePath -> IO (Digest SHA256)
hashFile fp = withBinaryFile fp ReadMode $ \h ->
    let loop context = do
            chunk <- B.hGetSome h 4096
            if B.null chunk
                then return $ hashFinalize context
                else loop $! hashUpdate context chunk
    in loop hashInit


processHash :: FilePath -> IO String
processHash fp = do
    digest <- show <$> hashFile fp
    putStrLn digest >> appendFile logFile (digest ++ "\n")
    return digest


findFile logfile = do
    fileData@(tmpFile, uploadName, contentType) <- lookFile "files"
    liftIO $ mapM_ (\x -> appendFile logfile (x ++ " ")) [tmpFile, uploadName, show contentType] >> appendFile logfile "\n"
    return fileData


processFile :: (IsString a, Show a) => String -> String -> IO (String, a)
processFile fileName uploadName = do
    t <- readProcess "yara" ["-w", "../rules/index.yar", fileName] ""
    let (result, tp) = if t == ""
        then ("Everything is OK with " ++ uploadName, "ok")
        else (parseError t uploadName, "error")
    putStrLn result >> appendFile logFile (result ++ "\n")
    return (result, tp)


processEmail :: Msg -> Adr -> IO ()
processEmail msg address = if elem '@' address
    then do
        getCredentials configFile >>= sendResult msg address
        putStrLn $ "Mail to: " ++ address ++ "\n"
        appendFile logFile $ "Mail to: " ++ address ++ "\n"
    else do
        putStrLn "No e-mail provided\n"
        appendFile logFile $ "No e-mail provided\n"


getCredentials file = take 2 <$> words <$> readFile file


processDateTime :: IO String -- (LocalTime DateTime)
processDateTime = do
    dtc <- localTimePrint formatTime <$> localDateCurrent
    --let sdtc = localTimePrint formatTime dtc
    putStrLn dtc >> appendFile logFile (dtc ++ "\n")
    return dtc


sendResult message address credentials = do
    sendMailWithLoginTLS "smtp.gmail.com" (credentials !! 0) (credentials !! 1) $ simpleMail
        (Address (Just "DAREMMA Group") "daremma@domain.com")
        [Address Nothing (pack address)]
        []
        []
        "Scaning result"
        [plainTextPart (fromStrict $ pack ""), htmlPart (fromStrict $ pack message)]


receiveFile :: ServerPart Response
receiveFile = setHeaderM "Access-Control-Allow-Origin" "*" *> do
    method POST

    time <- liftIO processDateTime

    fileData@(tmpFile, uploadName, contentType) <- findFile logFile


    (result, tp) <- liftIO $ processFile tmpFile uploadName
    address      <- show <$> lookText "mail"
    sha          <- liftIO $ processHash tmpFile

    let msg = result ++ "<br>SHA256: " ++ sha ++ "<br>at" ++ time

    liftIO $ processEmail msg address


    ok $ template "File uploaded" $
        templateBody [uploadName, show contentType, result, tp, sha, time]


templateBody args = do
    H.h1 $ toHtml ("Upload name:" :: Text)
    p ! A.id "upload-name" $ toHtml (args !! 0)
    H.h1 $ toHtml ("Content type:" :: Text)
    p $ toHtml $ (args !! 1)
    H.h1 $ toHtml ("Result:" :: Text)
    p ! A.id (fromString (args !! 3)) ! A.class_ "checking-result" $ toHtml $ show (args !! 2)
    H.h1 $ toHtml ("SHA256 sum:" :: Text)
    p ! A.id "sha256" $ toHtml $ args !! 4
    p ! A.id "time" $ toHtml $ args !! 5


formatPrint = mapM_ putStrLn . lines
parseError str upN = words str !! 0 ++ " at " ++ upN


myPolicy :: BodyPolicy
myPolicy = (defaultBodyPolicy "." (50*2^20) 1000 1000)


guardResponse :: ServerPart Response
guardResponse = do
    method GET
    serveDirectory DisableBrowsing ["main_page.html"] "Defender"

certbot :: ServerPart Response
certbot = do
    http
    method GET
    dir ".well-known" $ dir "acme-challenge" $ dir "GkQHaKJArek3RruqOT68xs6vv6eqliDSAnLfDCJ3scc" $
        serveFile (asContentType "text") ".well-known/acme-challenge/GkQHaKJArek3RruqOT68xs6vv6eqliDSAnLfDCJ3scc"

myApp :: ServerPart Response
myApp = do
    decodeBody myPolicy
    setHeaderM "Access-Control-Allow-Origin" "*" *> msum
        [ guardResponse
        , receiveFile
        , certbot
        ]
