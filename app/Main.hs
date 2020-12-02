import Control.Concurrent
import Control.Concurrent.MVar
import Happstack.Server
import Happstack.Server.SimpleHTTPS
import Lib

main :: IO ()
main = do
    httpsWait <- newEmptyMVar :: IO (MVar ())
    httpWait  <- newEmptyMVar :: IO (MVar ())
    forkIO $ simpleHTTPS confi1 myApp >> putMVar httpsWait ()
    forkIO $ simpleHTTP confi2 myApp  >> putMVar httpWait ()
    takeMVar httpsWait
    takeMVar httpWait
