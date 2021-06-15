-- Base
import XMonad hiding ( (|||) )
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)

import qualified XMonad.StackSet as W

    -- Actions
import XMonad.Actions.CopyWindow (kill1, killAllOtherCopies)
import XMonad.Actions.CycleWS (moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import qualified XMonad.Actions.TreeSelect as TS
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.SpawnOn
    -- Data
import Data.Char (isSpace)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
-- import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory

    -- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Fullscreen
import XMonad.Layout.LayoutCombinators

    -- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Layout.ShowWName
import XMonad.Layout.Spacing
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

    -- Prompt
import XMonad.Prompt
import XMonad.Prompt.Input
import XMonad.Prompt.FuzzyMatch
import XMonad.Prompt.Man
import XMonad.Prompt.Pass
import XMonad.Prompt.Shell (shellPrompt)
import XMonad.Prompt.Ssh
import XMonad.Prompt.XMonad
import Control.Arrow (first)
import Control.Monad

   -- Utilities
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import XMonad.Actions.Navigation2D
import XMonad.Actions.FloatKeys (keysResizeWindow)
import XMonad.Util.EZConfig (additionalKeysP)

myFont :: String
myFont = "xft:Roboto Mono:bold:size=9:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask       -- Sets modkey to super/windows key

myTerminal :: String
myTerminal = "alacritty"   -- Sets default terminal
-- myTerminal = "emacsclient -c -e '(multi-term)'"

myBrowser :: String
myBrowser = "vivaldi "               -- Sets qutebrowser as browser for tree select
-- myBrowser = myTerminal ++ " -e lynx " -- Sets lynx as browser for tree select

myEditor :: String
myEditor = "emacsclient -c -a emacs "  -- Sets emacs as editor for tree select

myBorderWidth :: Dimension
myBorderWidth = 3          -- Sets border width for windows

myNormColor :: String
myNormColor   = "#222222"  -- Border color of normal windows

myFocusColor :: String
myFocusColor  = "#aaaaaa"  -- Border color of focused windows

altMask :: KeyMask
altMask = mod1Mask         -- Setting this for use in xprompts

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myStartupHook :: X ()
myStartupHook = do
          spawnOnce "bash /home/rafael/nix-configs/wallpapers/update.sh"
          -- spawnOnce "volumeicon &"
          -- spawnOnce "trayer --edge bottom --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 0 --transparent true --alpha 0 --tint 0x0c0c0c  --height 16 &"
          -- spawnOnce "/usr/sbin/emacs --daemon &"
          -- spawnOnce "setxkbmap -layout us -variant altgr-intl -option caps:swapescape &"
          -- setWMName "LG3D"
          spawnOnOnce "emacs" "emacs"
          spawnOnOnce "web" "vivaldi"
          spawnOnce "flameshot"
          spawnOnce "nm-applet"
          spawnOnce "copyq"
          spawnOnce "polybar mybar"

myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
                  (0x28,0x2c,0x34) -- lowest inactive bg
                  (0x28,0x2c,0x34) -- highest inactive bg
                  (0xc7,0x92,0xea) -- active bg
                  (0xc0,0xa7,0x9a) -- inactive fg
                  (0x28,0x2c,0x34) -- active fg

-- Open scratch pads
myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" spawnTerm findTerm manageScratch
                , NS "spotify" spawnSpotify findSpotify manageScratch
                , NS "telegram" spawnTelegram findTelegram manageScratch
                , NS "discord" spawnDiscord findDiscord manageScratch
                ]
  where
    manageScratch = customFloating $ W.RationalRect l t w h
           where
             h = 0.9
             w = 0.9
             t = 0.95 -h
             l = 0.95 -w
    spawnTerm  = myTerminal ++ " -t scratch"
    findTerm   = title =? "scratch"
    spawnSpotify  = "spotify"
    findSpotify   = className =? "Spotify"
    spawnTelegram  = "telegram-desktop"
    findTelegram   = className =? "TelegramDesktop"
    spawnDiscord  = "discord"
    findDiscord   = className =? "discord"


mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Below is a variation of the above except no borders are applied
-- if fewer than two windows. So a single window has no gaps.
mySpacing' :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True

-- Make 2D navegation work nicely
myNavigation2DConfig = def { layoutNavigation = [
                                 ("grid", centerNavigation)
                               , ("magnify", centerNavigation)
                               , ("spirals", centerNavigation)
                               , ("threeCol", centerNavigation)
                               , ("tabs", centerNavigation)
                               , ("tall", centerNavigation)
                               ] }

-- Defining a bunch of layouts, many that I don't use.
tall     = renamed [Replace "tall"]
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
magnify  = renamed [Replace "magnify"]
           $ magnifier
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabConfig
  where
    myTabConfig = def { fontName            = "xft:Mononoki Nerd Font:regular:pixelsize=11"
                      , activeColor         = "#ffffff"
                      , inactiveColor       = "#3e445e"
                      , activeBorderColor   = "#000000"
                      , inactiveBorderColor = "#282c34"
                      , activeTextColor     = "#ffffff"
                      , inactiveTextColor   = "#d0d0d0"
                      }

-- Theme for showWName which prints current workspace when you change workspaces.
myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = "xft:Sans:bold:size=60"
    , swn_fade              = 1.0
    , swn_bgcolor           = "#000000"
    , swn_color             = "#FFFFFF"
    }

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out
     -- the full name of my workspaces.
     [ className =? "TelegramDesktop"     --> doFloat
     , className =? "copyq"     --> doFloat
     , className =? "spotify"     --> doFloat
     , className =? "Vivaldi-stable"     --> doShift ( myWorkspaces !! 0 )
     , className =? "Emacs"     --> doShift ( myWorkspaces !! 1 )
     -- , className =? "vlc"     --> doShift ( myWorkspaces !! 7 )
     ] <+> namedScratchpadManageHook myScratchPads

myLayoutHook = avoidStruts $ mouseResize $ windowArrange $
               mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     smartBorders tall
                                 ||| magnify
                                 ||| noBorders tabs

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
        doubleLts '<' = "<<"
        doubleLts x   = [x]

myWorkspaces = clickable . (map xmobarEscape)
               $ (["web", "emacs", "3", "4", "5", "6", "7", "8", "9", "10"])
  where
        clickable l = [ ws |
                      (i,ws) <- zip ([1..9])  l,
                      let n = i ]

myKeysP :: [(String, X ())]
myKeysP =
    -- Xmonad
        [ ("M-C-r", spawn "xmonad --recompile")      -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")        -- Restarts xmonad
        , ("M-S-e", io exitSuccess)                  -- Quits xmonad

    -- Open my preferred terminal
        , ("M-<Return>", spawn (myTerminal))

    -- Run Prompt
        , ("M-d", spawn "rofi -show drun -font \"Iosevka Fixed SS12 12\"")
        -- , ("M-d", spawn "dmenu_run -i -nf '#BBBBBB' -nb '#0c0c0c' -sb '#2f1e2e' -sf '#EEEEEE' -fn 'monospace-10' -p 'run:'")

    -- Windows
        , ("M-S-q", kill1)                           -- Kill the currently focused client
        , ("M-S-a", killAll)                         -- Kill all windows on current workspace

    -- Floating windows
        -- , ("M-f", sendMessage (T.Toggle "monocle"))       -- Toggles my 'monocle' layout
        , ("M-e", sendMessage (JumpToLayout "tall"))       -- Toggles my 'tall' layout
        , ("M-w", sendMessage (JumpToLayout "tabs"))       -- Toggles my 'tabs' layout
        , ("M-<Delete>", withFocused $ windows . W.sink) -- Push floating window back to tile
        , ("M-S-<Delete>", sinkAll)                      -- Push ALL floating windows to tile
        , ("M-S-C-l", withFocused (keysResizeWindow (-10,0) (1,1)))
        , ("M-S-C-h", withFocused (keysResizeWindow (10,0) (1,1)))
        , ("M-S-C-j", withFocused (keysResizeWindow (0,-10) (1,1)))
        , ("M-S-C-k", withFocused (keysResizeWindow (0,10) (1,1)))

    -- Windows navigation
        , ("M-m", windows W.focusMaster)     -- Move focus to the master window
        , ("M-<Right>", windowGo R False)
        , ("M-l", windowGo R False)
        , ("M-<Left>", windowGo L False)
        , ("M-h", windowGo L False)
        , ("M-<Up>", windowGo U False)
        , ("M-k", windowGo U False)
        , ("M-<Down>", windowGo D False)
        , ("M-j", windowGo D False)
        , ("M-S-k", switchLayer)

    -- Windows swapping
        , ("M-S-<Right>", windowSwap R False)
        , ("M-S-l", windowSwap R False)
        , ("M-S-<Left>", windowSwap L False)
        , ("M-S-h", windowSwap L False)
        , ("M-S-<Up>", windowSwap U False)
        , ("M-S-k", windowSwap U False)
        , ("M-S-<Down>", windowSwap D False)
        , ("M-S-j", windowSwap D False)
     --, ("M-S-m", windows W.swapMaster)    -- Swap the focused window and the master window
        -- , ("M-<Backspace>", promote)         -- Moves focused window to master, others maintain order
        , ("M1-S-<Tab>", rotSlavesDown)      -- Rotate all windows except master and keep focus in place
        , ("M1-C-<Tab>", rotAllDown)         -- Rotate all the windows in the current stack
        --, ("M-S-s", windows copyToAll)
        -- , ("M-C-s", killAllOtherCopies)

     -- Layouts
        , ("M-<Tab>", sendMessage NextLayout)                -- Switch to next layout
        , ("M-C-M1-<Up>", sendMessage Arrange)
        , ("M-C-M1-<Down>", sendMessage DeArrange)
        , ("M-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full
        , ("M-S-f", sendMessage ToggleStruts)         -- Toggles struts
        , ("M-S-n", sendMessage $ MT.Toggle NOBORDERS)      -- Toggles noborder
        , ("M-<KP_Multiply>", sendMessage (IncMasterN 1))   -- Increase number of clients in master pane
        , ("M-<KP_Divide>", sendMessage (IncMasterN (-1)))  -- Decrease number of clients in master pane
        , ("M-S-<KP_Multiply>", increaseLimit)              -- Increase number of windows
        , ("M-S-<KP_Divide>", decreaseLimit)                -- Decrease number of windows

     -- Window resize
        , ("M-C-h", sendMessage Shrink)                       -- Shrink horiz window width
        , ("M-C-<Left>", sendMessage Shrink)                       -- Shrink horiz window width
        , ("M-C-l", sendMessage Expand)                       -- Expand horiz window width
        , ("M-C-<Right>", sendMessage Expand)                       -- Expand horiz window width
        , ("M-C-j", sendMessage MirrorShrink)               -- Shrink vert window width
        , ("M-C-<Down>", sendMessage MirrorShrink)               -- Shrink vert window width
        , ("M-C-k", sendMessage MirrorExpand)               -- Exoand vert window width
        , ("M-C-<Up>", sendMessage MirrorExpand)               -- Exoand vert window width

    -- Workspaces
        , ("M-.", nextScreen)  -- Switch focus to next monitor
        , ("M-,", prevScreen)  -- Switch focus to prev monitor
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next ws
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to prev ws

    -- Scratchpads
        -- , ("M-C-<Return>", namedScratchpadAction myScratchPads "terminal")
        , ("M-C-c", namedScratchpadAction myScratchPads "spotify")
        , ("M-C-t", namedScratchpadAction myScratchPads "telegram")
        , ("M-C-d", namedScratchpadAction myScratchPads "discord")

    -- Apps
        , ("M-u", spawn "pavucontrol")
        , ("<XF86Tools>", spawn "pavucontrol")
        , ("M-p", spawn "flameshot gui")

    -- Emacs (CTRL-e followed by a key)
        , ("C-S-e e", spawn "emacsclient -c -a 'emacs'")                            -- start emacs

    -- Multimedia Keys
        , ("<XF86AudioPlay>", spawn "cmus toggle")
        , ("<XF86AudioPrev>", spawn "cmus prev")
        , ("<XF86AudioNext>", spawn "cmus next")
        , ("<XF86AudioMute>",   spawn "amixer set Master toggle")  -- Bug prevents it from toggling correctly in 12.04.
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%- unmute")
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+ unmute")
        , ("<XF86HomePage>", spawn "vivaldi")
        , ("<XF86Search>", safeSpawn "vivaldi" ["https://www.google.com/"])
        , ("<XF86Mail>", runOrRaise "geary" (resource =? "thunderbird"))
        , ("<XF86Calculator>", runOrRaise "gcalctool" (resource =? "gcalctool"))
        , ("<XF86Eject>", spawn "toggleeject")
        , ("<Print>", spawn "scrotd 0")
        ]
        -- Appending search engine prompts to keybindings list.
        -- The following lines are needed for named scratchpads.
          where nonNSP          = WSIs (return (\ws -> W.tag ws /= "nsp"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "nsp"))

main :: IO ()
main = do
    -- the xmonad, ya know...what the WM is named after!
    xmonad $ fullscreenSupport $ withNavigation2DConfig myNavigation2DConfig $ ewmh def
        { manageHook = ( isFullscreen --> doFullFloat ) <+> myManageHook <+> manageDocks
        -- Run xmonad commands from command line with "xmonadctl command". Commands include:
        -- shrink, expand, next-layout, default-layout, restart-wm, xterm, kill, refresh, run,
        -- focus-up, focus-down, swap-up, swap-down, swap-master, sink, quit-wm. You can run
        -- "xmonadctl 0" to generate full list of commands written to ~/.xsession-errors.
        , handleEventHook    = serverModeEventHookCmd
                               <+> serverModeEventHook
                               <+> serverModeEventHookF "XMONAD_PRINT" (io . putStrLn)
                               <+> docksEventHook
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        } `additionalKeysP` myKeysP
