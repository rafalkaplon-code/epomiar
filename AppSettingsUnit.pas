unit AppSettingsUnit;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  DataBaseManagerUnit;


type
  TAppSettings = class
  private
    class var FInstance: TAppSettings; // Singleton
    class var FDatabaseManager: TDatabaseManager; // Odwo³anie do instancji TDatabaseManager
    constructor Create; // Prywatny konstruktor
  public
    class function Instance: TAppSettings; // Globalny dostêp do instancji
    class procedure SetDatabaseManager(AManager: TDatabaseManager); // Ustawienie mened¿era bazy danych

    procedure SaveSetting(const SettingName, SettingValue: string);
    function GetSetting(const SettingName: string; const DefaultValue: string = ''): string;
  end;

implementation

{ TAppSettings }





(* Prywatny konstruktor *)
constructor TAppSettings.Create;
begin
  // kod inicjalizacji ...
  inherited Create;
end;





(* Singleton - globalny dostêp do instancji klasy *)
class function TAppSettings.Instance: TAppSettings;
begin
  if (FInstance = nil) and (FDatabaseManager = nil) then
    raise Exception.Create('Baza danych nie zosta³a jeszcze skonfigurowana');

  if FInstance = nil then
    FInstance := TAppSettings.Create;

  Result := FInstance;
end;







(* Ustawienie mened¿era bazy danych, aby TAppSettings móg³ korzystaæ z niego *)
class procedure TAppSettings.SetDatabaseManager(AManager: TDatabaseManager);
begin
  if FDatabaseManager = nil then
    FDatabaseManager := AManager
  else
    raise Exception.Create('Mened¿er bazy danych jest ju¿ skonfigurowany');
end;







(* Zapis ustawienia *)
procedure TAppSettings.SaveSetting(const SettingName, SettingValue: string);
begin
  if Assigned(FDatabaseManager) then
  begin
    try
      with FDatabaseManager.FQuery do
      begin
        SQL.Text := 'INSERT OR REPLACE INTO AppSetting (name, value) VALUES (:name, :value)';
        ParamByName('name').AsString := SettingName;
        ParamByName('value').AsString := SettingValue;
        ExecSQL;
      end;
    except
      on E: Exception do
        raise Exception.Create('B³¹d podczas zapisywania ustawienia: ' + E.Message);
    end;
  end
  else
    raise Exception.Create('Baza danych nie jest skonfigurowana.');
end;





(* Odczyt ustawienia *)
function TAppSettings.GetSetting(const SettingName: string; const DefaultValue: string = ''): string;
begin
  if Assigned(FDatabaseManager) then
  begin
    try
      with FDatabaseManager.FQuery do
      begin
        SQL.Text := 'SELECT value FROM AppSetting WHERE name = :name';
        ParamByName('name').AsString := SettingName;
        Open;

        if not Eof then
          Result := FieldByName('value').AsString
        else
          Result := DefaultValue; // Zwrócenie domyœlnej wartoœci
        Close;
      end;
    except
      on E: Exception do
        raise Exception.Create('B³¹d podczas odczytu ustawienia: ' + E.Message);
    end;
  end
  else
    raise Exception.Create('Baza danych nie jest skonfigurowana.');
end;



end.

