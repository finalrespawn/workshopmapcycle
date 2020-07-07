#include <sourcemod>
#include <workshopmap>

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#define PATH_WORKSHOP "maps/workshop"

public Plugin myinfo = {
	name = "Workshop Map Cycle",
	author = "Clarkey",
	description = "Makes an alphabetically arranged mapcycle.txt based on your workshop collection",
	version = "1.0",
	url = "http://finalrespawn.com"
};

Handle g_hMaps = null;

public void OnPluginStart()
{
	RegAdminCmd("sm_workshopmapcycle", Command_WorkshopMapCycle, ADMFLAG_CHANGEMAP);
}

public Action Command_WorkshopMapCycle(int client, int args)
{
	File hFile = OpenFile("mapcycle.txt", "w");
	
	char DirName[PLATFORM_MAX_PATH], FileName[PLATFORM_MAX_PATH], FilePath[PLATFORM_MAX_PATH], FullMaps[512][PLATFORM_MAX_PATH], ShortMaps[512][PLATFORM_MAX_PATH];
	FileType Type;
	
	DirectoryListing Dir = OpenDirectory(PATH_WORKSHOP);
	
	int MapCount;
	while (Dir.GetNext(DirName, sizeof(DirName), Type))
	{
		if (Type == FileType_Directory)
		{
			if ( !(StrEqual(DirName, ".") || StrEqual(DirName, "..")))
			{
				Format(DirName, sizeof(DirName), "%s/%s", PATH_WORKSHOP, DirName);
				DirectoryListing Dir2 = OpenDirectory(DirName);
				
				while (Dir2.GetNext(FileName, sizeof(FileName), Type))
				{
					if (Type == FileType_File)
					{
						if (StrContains(FileName, ".bsp") != -1)
						{
							ReplaceString(DirName, sizeof(DirName), "maps/", "");
							ReplaceString(FileName, sizeof(FileName), ".bsp", "");
							Format(FilePath, sizeof(FilePath), "%s/%s", DirName, FileName);
							FullMaps[MapCount] = FilePath;
						}
					}
				}
				
				MapCount++;
				delete Dir2;
			}
		}
	}
	
	g_hMaps = CreateKeyValues("maps");
	
	// Before we organise the map list we need to save their current position
	for (int i; i < MapCount; i++)
	{
		ShortMaps[i] = WorkshopToMap(FullMaps[i]);
		KvJumpToKey(g_hMaps, ShortMaps[i], true);
		KvSetNum(g_hMaps, "position", i);
		KvRewind(g_hMaps);
	}
	
	SortStrings(ShortMaps, MapCount, Sort_Ascending);
	
	for (int i; i < MapCount; i++)
	{
		KvJumpToKey(g_hMaps, ShortMaps[i]);
		int OldPos = KvGetNum(g_hMaps, "position");
		Format(FilePath, sizeof(FilePath), "%s/%s", FullPathToPath(FullMaps[OldPos]), ShortMaps[i]);
		hFile.WriteLine(FilePath);
		KvRewind(g_hMaps);
	}
	
	delete Dir;
	delete hFile;
	
	ReplyToCommand(client, "[SM] All maps added successfully. The map cycle will be updated on map change.");
}