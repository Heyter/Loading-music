#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

bool g_musicEnabled[MAXPLAYERS + 1];
Handle g_Cookie_Enabled;
ConVar UrlLoad;
ConVar UrlAfterLoad;

public Plugin myinfo = {
	name = "Loading Screen Music",
	author = "The casual trade and fun server",
	description = "Plays music during mapchange",
	version = PLUGIN_VERSION,
	url = "http://tf2-casual-fun.de"
};

public void OnPluginStart()
{
	CreateConVar("sm_loadingmusic_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	UrlLoad = CreateConVar("sm_loadingmusic_url", "", "Url of the loading music");
	UrlAfterLoad = CreateConVar("sm_loadingmusic_doneurl", "", "Url after the client connected");

	AutoExecConfig();

	g_Cookie_Enabled = RegClientCookie("loadingmusic_enabled", "Enable/Disable Loading Music", CookieAccess_Protected);
	SetCookieMenuItem(CookieMenu_TopMenu, g_Cookie_Enabled, "Loading Music");

	HookEvent("player_disconnect", Client_Disconnected, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	char url[512];
	UrlAfterLoad.GetString(url, sizeof(url));

	if(StrEqual(url, ""))
		strcopy(url, sizeof(url), "about:blank");

	DoUrl(client, url);
}

public void Client_Disconnected(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_musicEnabled[client] = false;
	DoUrl(client, "about:blank");
}

public void OnClientDisconnect(int client)
{
	char url[512];
	UrlLoad.GetString(url, sizeof(url));

	if(StrEqual(url, ""))
		strcopy(url, sizeof(url), "about:blank");

	if(g_musicEnabled[client])
		DoUrl(client, url);
}

public void OnClientCookiesCached(int client)
{
	char sEnabled[2];
	GetClientCookie(client, g_Cookie_Enabled, sEnabled, sizeof(sEnabled));
	g_musicEnabled[client] = StrEqual(sEnabled, "1");
}

public void CookieMenu_TopMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action != CookieMenuAction_DisplayOption)
		SendCookieEnabledMenu(client);
}

stock void SendCookieEnabledMenu(int client)
{
	Handle hMenu = CreateMenu(Menu_CookieSettingsEnable);
	SetMenuTitle(hMenu, "Enable/Disable Loading Music");

	if (g_musicEnabled[client])
	{
		AddMenuItem(hMenu, "enable", "Enable (Set)");
		AddMenuItem(hMenu, "disable", "Disable");
	}
	else
	{
		AddMenuItem(hMenu, "enable", "Enabled");
		AddMenuItem(hMenu, "disable", "Disable (Set)");
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Menu_CookieSettingsEnable(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			SetClientCookie(client, g_Cookie_Enabled, "1");
			g_musicEnabled[client] = true;
			PrintToChat(client, "[SM] Loading Music is ENABLED");
		}
		else
		{
			SetClientCookie(client, g_Cookie_Enabled, "0");
			g_musicEnabled[client] = false;
			PrintToChat(client, "[SM] Loading Music is DISABLED");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			ShowCookieMenu(client);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

void DoUrl(client, char[] url)
{
	Handle setup = CreateKeyValues("data");

	KvSetString(setup, "title", "Loading Music");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);

	ShowVGUIPanel(client, "info", setup, false);
	PrintToServer("client %L has url: %s", client, url);
	CloseHandle(setup);
}
