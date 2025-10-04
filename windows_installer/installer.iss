[Setup]
AppName=RasterFlow
AppVersion=0.1.0
AppPublisher=Flatscrew
DefaultDirName={commonpf}\RasterFlow
DefaultGroupName=RasterFlow
UninstallDisplayIcon={app}\rasterflow.exe
Compression=lzma
SolidCompression=yes
OutputBaseFilename=rasterflow-setup
OutputDir=.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes

[Files]
Source: "..\dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\RasterFlow"; Filename: "{app}\rasterflow.exe"
Name: "{commondesktop}\RasterFlow"; Filename: "{app}\rasterflow.exe"

[Run]
Filename: "{app}\rasterflow.exe"; Description: "Launch RasterFlow"; Flags: nowait postinstall skipifsilent
