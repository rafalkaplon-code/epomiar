program ePomiar;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  AppSettingsUnit in 'AppSettingsUnit.pas',
  DataBaseManagerUnit in 'DataBaseManagerUnit.pas',
  SecondUnit in 'SecondUnit.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
