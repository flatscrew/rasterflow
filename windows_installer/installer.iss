[Setup]
AppName=RasterFlow
AppVersion={#Version}
AppPublisher=Flatscrew
DefaultDirName={commonpf}\RasterFlow
DefaultGroupName=RasterFlow
UninstallDisplayIcon={app}\rasterflow.exe
Compression=lzma
SolidCompression=yes
OutputBaseFilename=RasterFlow-{#Version}-Setup-win64
OutputDir=.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
ChangesEnvironment=yes

[Files]
Source: "..\dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\RasterFlow"; Filename: "{app}\rasterflow.exe"
Name: "{commondesktop}\RasterFlow"; Filename: "{app}\rasterflow.exe"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "BABL_PATH"; ValueData: "{app}\lib\babl-0.1"; Flags: preservestringtype uninsdeletevalue
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "GEGL_PATH"; ValueData: "{app}\lib\gegl-0.4"; Flags: preservestringtype uninsdeletevalue

[Run]
Filename: "{app}\rasterflow.exe"; Description: "Launch RasterFlow"; Flags: nowait postinstall skipifsilent
