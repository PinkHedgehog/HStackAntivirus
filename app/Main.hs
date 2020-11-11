{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
import Control.Applicative ((<$>), optional)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text.Lazy (unpack)
import Happstack.Lite
import Control.Monad.IO.Class (liftIO)
import Text.Blaze.Html5 (Html, (!), a, form, input, p, toHtml, label)
import Text.Blaze.Html5.Attributes (action, enctype, href, name, size, type_, value)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import System.Directory
import System.Process

template :: Text -> Html -> Response
template title body = toResponse $
    H.html $ do
        H.head $ do
            H.link ! type_ "text/css" ! A.rel "stylesheet" ! href "https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"
            H.title (toHtml title)
        H.body $ do
          body


--
confi1 = ServerConfig { port      = 8000
                      , ramQuota  = 1 * 10^6
                      , diskQuota = 20 * 10^6
                      , tmpDir    = "."
                      }



receiveRemote :: ServerPart Response
receiveRemote = setHeaderM "Access-Control-Allow-Origin" "*" *> do
    method POST

    (tmpFile, uploadName, contentType) <- lookFile "files"
    liftIO $ mapM_ (\x -> putStr (x ++ " ")) [tmpFile, uploadName, show contentType]

    (result, tp) <- liftIO $ do
        t <- readProcess "../../yara-4.0.2/yara" ["-w", "../../YARA/rules/index.yar", tmpFile] ""
        if t == "" then return ("Everything is OK", "ok") else return (t, "error")

    ok $ template "File uploaded" $ do
        H.h1 $ toHtml ("Upload name:" :: Text)
        p ! A.id "upload-name" $ toHtml uploadName
        H.h1 $ toHtml ("Content type:" :: Text)
        p $ toHtml $ show contentType
        H.h1 $ toHtml ("Result:" :: Text)
        p ! A.id tp ! A.class_ "checking-result" $ toHtml $ show result

    where
        formatPrint = mapM_ putStrLn . lines


receiveText :: ServerPart Response
receiveText = setHeaderM "Access-Control-Allow-Origin" "*" >> do
    --liftIO $ putStrLn "Receiving text..."
    method POST

    txt <- lookText "name"
    liftIO $ putStrLn . show $ txt

    ok $ toResponse ("Received text!" :: Text)

guardResponce :: ServerPart Response
guardResponce = do
    method GET
    serveDirectory DisableBrowsing ["main_page.html"] "Defender"
            -- msum [ serveFile (asContentType "file") "pic"
            --      , serveFile (asContentType "text/html") "scan_page.html"
            --      , serveFile (asContentType "text/css") "scan_page.css"
            --      , serveFile (guessContentTypeM mimeTypes) "main.js"
            --      ]
        -- resp = do
        --     method GET
        --     ok $ template "Somtething happened" $ do
        --         H.h1 (toHtml $ ("or nothing?" :: Text))

myApp :: ServerPart Response
myApp = setHeaderM "Access-Control-Allow-Origin" "*" *> msum
    [ receiveRemote
    , guardResponce
    , receiveText
    ]

main :: IO ()
main = do
    serve (Just confi1) myApp
