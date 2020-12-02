{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
module Lib where
--(confi1, confi2, myApp)
import Control.Applicative ((<$>), optional)
import Data.Maybe (fromMaybe)
import Data.Text (Text, pack)
import Data.Text.Lazy (unpack, fromStrict)
import qualified Data.Text.Internal.Lazy as LT
import Happstack.Server
import Happstack.Server.SimpleHTTPS
import Control.Monad (when, msum)
import Control.Monad.IO.Class (liftIO)
import Text.Blaze.Html5 (Html, (!), a, form, input, p, toHtml, label)
import Text.Blaze.Html5.Attributes (action, enctype, href, name, size, type_, value)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import System.Directory hiding (findFile)
import System.Process
import Network.Mail.SMTP hiding (Response)
import Data.String

configFile = "config.conf"
logFile = "logger.txt"
confi2 = nullConf { port = 80 }
confi1 = nullTLSConf { tlsPort = 443
                     , tlsCert = "server101.mycloud.crt"
                     , tlsKey  =  "server101.mycloud.key"
                     , tlsCA = Just "rootCA.crt"
                     }

template :: Text -> Html -> Response
template title body = toResponse $
    H.html $ do
        H.head $ do
            H.title (toHtml title)
        H.body $ do
          body

findFile logfile = do
    (tmpFile, uploadName, contentType) <- lookFile "files"
    liftIO $ mapM_ (\x -> appendFile logfile (x ++ " ")) [tmpFile, uploadName, show contentType] >> appendFile logfile "\n"
    return (tmpFile, uploadName, contentType)

processFile :: (IsString a) => String -> String -> IO (String, a)
processFile fileName uploadName = do
    t <- readProcess "yara" ["-w", "../rules/index.yar", fileName] ""
    let (result, tp) = if t == ""
        then ("Everything is OK", "ok")
        else (parseError t uploadName, "error")
    putStrLn result >> appendFile logFile (result ++ "\n")
    return (result, tp)

processEmail :: String -> String -> IO ()
processEmail result address = if elem '@' address
    then do
        getCredentials configFile >>= sendResult result address
        putStrLn $ "Mail to: " ++ address ++ "\n"
        appendFile logFile $ "Mail to: " ++ address ++ "\n"
    else do
        putStrLn "No e-mail provided\n"
        appendFile logFile $ "No e-mail provided\n"

getCredentials file = take 2 <$> words <$> readFile file

sendResult message address credentials = do
    sendMailWithLoginTLS "smtp.gmail.com" (credentials !! 0) (credentials !! 1) $ simpleMail
        (Address (Just "DAREMMA Group") "daremma@domain.com")
        [Address Nothing (pack address)]
        []
        []
        "Scaning result"
        [plainTextPart (fromStrict $ pack message), htmlPart (fromStrict $ pack message)]

receiveFile :: ServerPart Response
receiveFile = setHeaderM "Access-Control-Allow-Origin" "*" *> do
    method POST

    fileData@(tmpFile, uploadName, contentType) <- findFile logFile

    (result, tp) <- liftIO $ processFile tmpFile uploadName
    address      <- show <$> lookText "mail"

    liftIO $ processEmail result address

    ok $ template "File uploaded" $
        templateBody [uploadName, show contentType, result, tp]

templateBody args = do
    H.h1 $ toHtml ("Upload name:" :: Text)
    p ! A.id "upload-name" $ toHtml (args !! 0)
    H.h1 $ toHtml ("Content type:" :: Text)
    p $ toHtml $ show (args !! 1)
    H.h1 $ toHtml ("Result:" :: Text)
    p ! A.id (fromString (args !! 3)) ! A.class_ "checking-result" $ toHtml $ show (args !! 2)

formatPrint = mapM_ putStrLn . lines
parseError str upN = words str !! 0 ++ " at " ++ upN


myPolicy :: BodyPolicy
myPolicy = (defaultBodyPolicy "." (50*2^20) 1000 1000)

guardResponse :: ServerPart Response
guardResponse = do
    method GET
    serveDirectory DisableBrowsing ["main_page.html"] "Defender"

myApp :: ServerPart Response
myApp = do
    decodeBody myPolicy
    setHeaderM "Access-Control-Allow-Origin" "*" *> msum
        [ guardResponse
        , receiveFile
        ]
