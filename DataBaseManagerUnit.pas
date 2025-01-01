unit DataBaseManagerUnit;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Pool,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.UI.Intf,
  FMX.Grid,
  Data.DB,
  FireDAC.Comp.DataSet,
  System.IOUtils,
  FMX.Dialogs;

// Klasa zarzadzajaca baz¹ danych
type
  TDatabaseManager = class
  private


  public
    FConnection: TFDConnection;
    FQuery: TFDQuery;

    constructor Create;
    destructor Destroy; override;
    procedure ConnectToDatabase;
    procedure LoadProducts(Grid: TStringGrid);
    procedure InsertProduct(Length, Diameter, Width, Height, Volume: Real; Quantity, Pack_id, Tree_id, Quality_id : Integer);
  end;


implementation

{ TDatabaseManager }


(* Konstruktor *)
constructor TDatabaseManager.Create;
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FConnection;
end;



(* Destruktor *)
destructor TDatabaseManager.Destroy;
begin
  // Roz³¹czenie z baz¹
  if FConnection.Connected then
    FConnection.Connected := False;

  // Zwolnienie zasobów
  FQuery.Free;
  FConnection.Free;
  inherited;
end;



(* Po³¹czenie do bazy danych *)
procedure TDatabaseManager.ConnectToDatabase;
var
  DBFilePath: string;
begin
  // Œcie¿ka do bazy danych w katalogu aplikacji
  DBFilePath := TPath.Combine(TPath.GetDocumentsPath, 'database.db');
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := DBFilePath;
  FConnection.LoginPrompt := False;

  // kontrola jednokrotnego uruchomienia procedury
   if not FConnection.Connected then
   begin
      // gdy plik db istnieje
      if FileExists(DBFilePath) then
      begin
          try
            FConnection.Connected := True;
            FQuery.Connection := FConnection;
            ShowMessage('Baza danych istneje, po³¹czona pomyœlnie');

          except
            on E: Exception do
              ShowMessage('B³¹d podczas ³¹czenia do istnej¹cej bazy danych: ' + E.Message);
          end
      end

      else  // gdy plik db NIE istnieje

        begin
        ShowMessage('Baza danych nie istnieje. Tworzê now¹ bazê danych');
            try
                FConnection.Connected := True;
                FQuery.Connection := FConnection;

                // Tworzenie tabeli Product - przetworzone produkty
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS Product (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
                  'length REAL, ' +
                  'diameter REAL, ' +
                  'width REAL, ' +
                  'height REAL, ' +
                  'quantity INTEGER, ' +
                  'volume REAL, ' +
                  'pack_id INTEGER, ' +
                  'tree_id INTEGER, ' +
                  'quality_id INTEGER, ' +
                  // Deklaracje kluczy obcych
                  'FOREIGN KEY (pack_id) REFERENCES Pack(id), ' +
                  'FOREIGN KEY (tree_id) REFERENCES Tree(id), ' +
                  'FOREIGN KEY (quality_id) REFERENCES Quality(id) );';
                FQuery.ExecSQL;

                // Tworzenie tabeli Pack - paczki materia³u
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS Pack (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'name TEXT);';
                FQuery.ExecSQL;

                // Tworzenie tabeli Trees - nazwa gatunku drzewa
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS Tree (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'name TEXT);';
                FQuery.ExecSQL;

                // Tworzenie tabeli Quality - nazwa klasy jakoœci produktu
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS Quality (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'name TEXT);';
                FQuery.ExecSQL;

                // Tworzenie tabeli AppSetting - ustawienia aplikacji
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS AppSetting (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'name TEXT, ' +
                  'value TEXT);';
                FQuery.ExecSQL;

                ShowMessage('Baza danych zosta³a utworzona pomyœlnie');

            except
              on E: Exception do
                ShowMessage('B³¹d podczas tworzenia bazy danych: ' + E.Message);
            end;

        end

    end;

end;



(* £adowanie listy produktów do tabeli *)
procedure TDatabaseManager.LoadProducts(Grid: TStringGrid);
var
  i, j: Integer;
  Field: TField;
  Col: TStringColumn;

begin
  try
      try
          FQuery.SQL.Text := 'SELECT * FROM Product ORDER BY timestamp DESC;';
          FQuery.Open;

          // Usuniêcie istniej¹cych kolumn
          Grid.ClearColumns;

          // Tworzenie kolumn na podstawie pól zapytania
          for j := 0 to FQuery.FieldCount - 1 do
            begin
              Col := TStringColumn.Create(Grid);
              Col.Header := FQuery.Fields[j].FieldName; // Nazwa kolumny
              Grid.AddObject(Col);
            end;

          // Ustawienie liczby wierszy
          Grid.RowCount := FQuery.RecordCount + 1; // Nag³ówek + dane

          // Wype³nianie danych
          i := 1; // Pierwszy wiersz na dane, zerowy na nag³ówki
          while not FQuery.Eof do
            begin
                for j := 0 to FQuery.FieldCount - 1 do
                begin
                  Field := FQuery.Fields[j];
                  Grid.Cells[j, i] := Field.AsString; // Wype³nienie komórki
                end;
                Inc(i);
                FQuery.Next;
            end;
          FQuery.Close;

      except
          on E: Exception do
            ShowMessage('B³¹d podczas ³adowania produktów: ' + E.Message);
      end;

  finally
    FQuery.Close; // Zamykanie bez wzglêdu na wynik
  end;
end;



(* Dodawanie nowego produktu *)
procedure TDatabaseManager.InsertProduct(Length, Diameter, Width, Height, Volume: Real; Quantity, Pack_id, Tree_id, Quality_id : Integer);
begin
    try
        FQuery.SQL.Text := 'INSERT INTO Product (length, diameter, width, height, volume, quantity, pack_id, tree_id, quality_id) VALUES (:L, :D, :W, :H, :V, :Q, :PID, :TID, :QID);';
        FQuery.ParamByName('L').AsFloat := Length;
        FQuery.ParamByName('D').AsFloat := Diameter;
        FQuery.ParamByName('W').AsFloat := Width;
        FQuery.ParamByName('H').AsFloat := Height;
        FQuery.ParamByName('V').AsFloat := Volume;
        FQuery.ParamByName('Q').AsInteger := Quantity;
        FQuery.ParamByName('PID').AsInteger := Pack_id;
        FQuery.ParamByName('TID').AsInteger := Tree_id;
        FQuery.ParamByName('QID').AsInteger := Quality_id;
        FQuery.ExecSQL;
    except
        on E: Exception do
          ShowMessage('B³¹d podczas dodawania produktu: ' + E.Message);
    end;

end;

end.

