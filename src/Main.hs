{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
module Main where

import Control.Exception
import Control.Monad
import Data.Monoid
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath
import System.IO.Error

import qualified Codec.Archive.Zip as Zip
import qualified Data.Binary as Binary
import Data.Default (def)
import Data.Text (Text)
import qualified Data.Text.IO as T
import qualified Data.Text.Encoding as T
import Data.Vector (Vector)
import qualified Data.Vector as V
import qualified GitHub.Endpoints.Repos.Releases as GH
import Network.HTTP.Req
import System.Directory (createDirectoryIfMissing)
import System.Process (spawnCommand)

repo :: IO (GH.Name GH.Owner, GH.Name GH.Repo)
repo = pure ("PoE-TradeMacro", "POE-TradeMacro")

trademacroDir :: IO FilePath
trademacroDir = pure "trademacro"

versionFile :: IO FilePath
versionFile = (</> "version.txt") <$> trademacroDir

userAgent :: Option scheme
userAgent = header "User-Agent" "PoE-TradeMacro updater by Solonarv: https://github.com/Solonarv/poe-trade-macro-updater"

main :: IO ()
main = do
  rel <- exitIfError =<< uncurry GH.releases =<< repo
  ver <- getInstalledVersion
  let diff = V.takeWhile ((/= ver) . GH.releaseTagName) rel
  if V.null diff
    then putStrLn "Already up to date"
    else do
      printChanges diff
      when (V.null $ GH.releaseAssets $ V.head diff) $
        putStrLn "Newest release has no associated assets! Using newest existing release instead."
      let releasesWithAssets = V.filter (not . V.null . GH.releaseAssets) diff
      when (V.null releasesWithAssets) $
        putStrLn "No new release with downloadable assets found. Exiting." >> exitFailure
      downloadAndInstall $ V.head releasesWithAssets
  args <- getArgs
  when (not $ "--nolaunch" `elem` args) $
    putStrLn "Launching TradeMacro..." >> launchTradeMacro

exitIfError :: Show err => Either err a -> IO a
exitIfError = either (\e -> print e >> exitFailure) pure

getInstalledVersion :: IO Text
getInstalledVersion = do
  fp <- versionFile
  T.readFile fp `catch` \e -> if isDoesNotExistError e then pure "" else throwIO e

printChanges :: Vector GH.Release -> IO ()
printChanges diff = do
  when (V.length diff > 5) $
    putStrLn "Printing 5 most recent changelogs:"
  forM_ (V.take 5 diff) printChange
  where
    printChange GH.Release{..} = do
      T.putStrLn $ "\n" <> releaseName <> " by " <> (usrName releaseAuthor)
      T.putStrLn $ releaseBody
    usrName = GH.untagName . GH.simpleUserLogin

downloadAndInstall :: GH.Release -> IO ()
downloadAndInstall GH.Release{..} = do
  T.putStrLn $ "Downloading release " <> releaseName
  let downloadUrl = GH.releaseAssetBrowserDownloadUrl $ V.head $ releaseAssets
  T.putStrLn $ "Fetch " <> downloadUrl
  let Just (reqUrl, opts) = parseUrlHttps $ T.encodeUtf8 downloadUrl
  response <- runReq def $ req GET reqUrl NoReqBody lbsResponse (opts <> userAgent)
  -- print $ responseBody response
  let archive = Binary.decode $ responseBody response
  dest <- trademacroDir
  putStrLn $ "Extracting to " <> dest
  createDirectoryIfMissing False dest
  Zip.extractFilesFromArchive [Zip.OptDestination dest] archive
  T.putStrLn $ "Updated to version " <> releaseName
  vf <- versionFile
  T.writeFile vf releaseTagName

launchTradeMacro :: IO ()
launchTradeMacro = do
  launchTarget <- (</> "Run_TradeMacro.ahk") <$> trademacroDir
  () <$ spawnCommand ("start " <> launchTarget)