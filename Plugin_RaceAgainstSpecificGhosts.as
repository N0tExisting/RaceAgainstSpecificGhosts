#name "RaceAgainstSpecificGhosts"
#author "https://openplanet.nl/u/banjee, malon, Discord user Ties0017#0017, Discord user 100480922406653952"
#category "Race"
#perms "full"
//v1.1

#include "Formatting.as"
#include "Time.as"
#include "Icons.as"

string name = "";
string inputUrl = "";
string savedMessage = "";
bool urlSent = false;
bool windowVisible = false;

void log(string msg)
{
    print("[\\$9cf" + name + "\\$fff] " + msg);
}

void RenderMenu()
{
    if (UI::MenuItem("\\$999" + Icons::Download + "\\$z Race Against Specifc Ghost", "", windowVisible) && !windowVisible)
    {
        windowVisible = !windowVisible;
    }
}

void RenderInterface()
{
    if (windowVisible)
    {
        UI::Begin("Race Against Specifc Ghost", windowVisible, UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize);

        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap !is null)
        {
            UI::Text("Paste the URL of the Specific Ghost from trackmania.io below");
            UI::Text("or paste the path of a downloaded Replay.Gbx file.");
            inputUrl = UI::InputText("Ghost URL", inputUrl);
            UI::Text("\\$f99WARNING:\\$ccc An invalid URL will result in the game crashing (unconfirmed)");
            if (!urlSent && UI::Button("Load Specific Ghost"))
            {
                urlSent = true;
            }
            if (savedMessage != "")
            {
                UI::Text(savedMessage);
            }
        }
        else
        {
            UI::Text("Play the track you want to combine the ghost(s) with");
            savedMessage = "";
        }

        UI::End();
    }
}

CGameDataFileManagerScript@ TryGetDataFileMgr()
{
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app !is null)
    {
        CSmArenaRulesMode@ playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
        if (playgroundScript !is null)
        {
            CGameDataFileManagerScript@ dataFileMgr = cast<CGameDataFileManagerScript>(playgroundScript.DataFileMgr);
            if (dataFileMgr !is null)
            {
                return dataFileMgr;
            }
        }
    }
    return null;
}

CSmArenaRulesMode@ getPGS() {
    auto app = cast<CTrackMania@>(GetApp());
    return cast<CSmArenaRulesMode@>(app.PlaygroundScript);
}

void Main()
{
    name = Meta::ExecutingPlugin().Name;
    log("Initializing");

    while (true)
    {
        if (urlSent)
        {
            auto dataFileMgr = TryGetDataFileMgr();
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (IO::FileExists(inputUrl)){
                log("File Found, opening...");
                CWebServicesTaskResult_GhostListScript@ ghosts = dataFileMgr.Replay_Load(inputUrl);
                auto singleGhost = ghosts.Ghosts[0];
                auto pgs = getPGS();
                pgs.Ghost_Add(singleGhost, true);
            }else{
                log("Download triggered for " + inputUrl);
                if (dataFileMgr !is null && app.RootMap !is null && inputUrl != "")
                {
                    CWebServicesTaskResult_GhostScript@ result = dataFileMgr.Ghost_Download("", inputUrl);
                    uint timeout = 20000;
                    uint currentTime = 0;
                    while (result.Ghost is null && currentTime < timeout)
                    {
                        currentTime += 100;
                        sleep(100);
                    }
                    CGameGhostScript@ ghost = cast<CGameGhostScript>(result.Ghost);
                    if (ghost !is null)
                    {
                        auto pgs = getPGS();
                        pgs.Ghost_Add(ghost, true);
                    }
                    else
                    {
                        log("Download Failed");
                    }
                }
                else
                {
                    log("Error: dataFileMgr was null, app.RootMap was null, or inputUrl was emptyString");
                }
            }
            inputUrl = "";
            urlSent = false;
            savedMessage = "";
            log("Ghost Loaded Successfully.");
        }
        sleep(1000);
    }
}
