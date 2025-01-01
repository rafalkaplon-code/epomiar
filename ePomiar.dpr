program ePomiar;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  AppSettingsUnit in 'AppSettingsUnit.pas',
  DataBaseManagerUnit in 'DataBaseManagerUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
