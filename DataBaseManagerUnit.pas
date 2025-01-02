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

// Klasa zarzadzajaca baz� danych
type
  TDatabaseManager = class
  private


  public
    FConnection: TFDConnection;
    FQuery: TFDQuery;

    constructor Create;
    destructor Destroy; override;
    procedure ConnectToDatabase;
    procedure InsertProduct(Length, Diameter, Width, Height, Volume: Real; Quantity, Pack_id, Tree_id, Quality_id : Integer);
    procedure LoadProducts(Grid: TStringGrid);
    procedure LoadProductsLazy(Grid: TStringGrid; PageSize: Integer);
  end;



const
  ColumnDefinitions: array[0..10] of record
    FieldName: string;   // Nazwa pola w bazie danych
    DisplayName: string; // Przyjazna nazwa kolumny
    Width: Single;       // Szeroko�� kolumny
    Visible: Boolean;    // Czy kolumna ma by� widoczna
    UnitName: string;    // Dodawana jednostka
  end =
  (
    (FieldName: 'id';         DisplayName: 'ID';        Width: 40;  Visible: True;   UnitName: ''),
    (FieldName: 'timestamp';  DisplayName: 'Data';      Width: 100; Visible: False;  UnitName: ''),
    (FieldName: 'length';     DisplayName: 'D�ugo��';   Width: 100; Visible: True;   UnitName: 'm'),
    (FieldName: 'diameter';   DisplayName: '�rednica';  Width: 100; Visible: True;   UnitName: 'cm'),
    (FieldName: 'width';      DisplayName: 'Szeroko��'; Width: 100; Visible: False;  UnitName: 'cm'),
    (FieldName: 'height';     DisplayName: 'Wysoko��';  Width: 100; Visible: False;  UnitName: 'cm'),
    (FieldName: 'quantity';   DisplayName: 'Ilo��';     Width: 80;  Visible: False;  UnitName: 'x'),
    (FieldName: 'volume';     DisplayName: 'Obj�to��';  Width: 100; Visible: True;   UnitName: 'm' + Chr(179);),
    (FieldName: 'pack_id';    DisplayName: 'ID Paczki'; Width: 100; Visible: False;  UnitName: ''),
    (FieldName: 'tree_id';    DisplayName: 'ID Drzewa'; Width: 100; Visible: False;  UnitName: ''),
    (FieldName: 'quality_id'; DisplayName: 'Jako��';    Width: 100; Visible: False;  UnitName: '')
  );







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
  // Roz��czenie z baz�
  if FConnection.Connected then
    FConnection.Connected := False;

  // Zwolnienie zasob�w
  FQuery.Free;
  FConnection.Free;
  inherited;
end;



(* Po��czenie do bazy danych *)
procedure TDatabaseManager.ConnectToDatabase;
var
  DBFilePath: string;
begin
  // �cie�ka do bazy danych w katalogu aplikacji
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
            ShowMessage('Baza danych istneje, po��czona pomy�lnie');

          except
            on E: Exception do
              ShowMessage('B��d podczas ��czenia do istnej�cej bazy danych: ' + E.Message);
          end
      end

      else  // gdy plik db NIE istnieje

        begin
        ShowMessage('Baza danych nie istnieje. Tworz� now� baz� danych');
            try
                FConnection.Connected := True;
                FQuery.Connection := FConnection;

                // Tworzenie tabeli Product - przetworzone produkty
                FQuery.SQL.Text :=
                  'CREATE TABLE IF NOT EXISTS Product (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
                  'length REAL NOT NULL, ' +
                  'diameter REAL NULL, ' +
                  'width REAL NULL, ' +
                  'height REAL NULL, ' +
                  'quantity INTEGER NULL, ' +
                  'volume REAL NULL, ' +
                  'pack_id INTEGER DEFAULT NULL, ' +
                  'tree_id INTEGER DEFAULT NULL, ' +
                  'quality_id INTEGER DEFAULT NULL, ' +
                  'FOREIGN KEY (pack_id) REFERENCES Pack(id) ON DELETE SET NULL, ' +
                  'FOREIGN KEY (tree_id) REFERENCES Tree(id) ON DELETE SET NULL, ' +
                  'FOREIGN KEY (quality_id) REFERENCES Quality(id) ON DELETE SET NULL );';
                FQuery.ExecSQL;

                // Tworzenie tabeli Pack - paczki materia�u
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

                // Tworzenie tabeli Quality - nazwa klasy jako�ci produktu
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

                ShowMessage('Baza danych zosta�a utworzona pomy�lnie');

            except
              on E: Exception do
                ShowMessage('B��d podczas tworzenia bazy danych: ' + E.Message);
            end;

        end

    end;

end;



(* �adowanie listy produkt�w do tabeli *)
procedure TDatabaseManager.LoadProducts(Grid: TStringGrid);
var
  i, j, ColIndex: Integer;
  Field: TField;
  Col: TStringColumn;
begin
  try
    try
      // Konfiguracja FireDAC
      FQuery.FetchOptions.RecordCountMode := cmTotal;

      // Zapytanie SQL
      FQuery.SQL.Text := 'SELECT id, timestamp, length, diameter, width, height, ' +
                         'quantity, volume, pack_id, tree_id, quality_id ' +
                         'FROM Product ORDER BY timestamp DESC LIMIT 500;';
      FQuery.Open;

      // Usuni�cie istniej�cych kolumn
      Grid.ClearColumns;

      // Tworzenie kolumn na podstawie ustawie�
      ColIndex := 0; // Numer kolumny w TStringGrid
      for j := Low(ColumnDefinitions) to High(ColumnDefinitions) do
      begin
        if ColumnDefinitions[j].Visible then // Sprawdzenie widoczno�ci kolumny
        begin
          Col := TStringColumn.Create(Grid);
          Col.Header := ColumnDefinitions[j].DisplayName; // Przyjazna nazwa
          Col.Width := ColumnDefinitions[j].Width;        // Szeroko��
          Grid.AddObject(Col);
          Inc(ColIndex); // Zwi�kszenie indeksu kolumny tylko dla widocznych
        end;
      end;

      // Ustawienie liczby wierszy
      Grid.RowCount := FQuery.RecordCount + 1;

      // Wype�nianie danych
      i := 0;
      while not FQuery.Eof do
      begin
        ColIndex := 0; // Numer kolumny w TStringGrid
        for j := Low(ColumnDefinitions) to High(ColumnDefinitions) do
        begin
          if ColumnDefinitions[j].Visible then // Sprawdzenie widoczno�ci kolumny
          begin
            Field := FQuery.FieldByName(ColumnDefinitions[j].FieldName);
            Grid.Cells[ColIndex, i] := Field.AsString + ' ' + ColumnDefinitions[j].UnitName; // Wype�nienie danych
            Inc(ColIndex); // Przesuni�cie tylko dla widocznych kolumn
          end;
        end;
        Inc(i);
        FQuery.Next;
      end;
      FQuery.Close;

    except
      on E: Exception do
        ShowMessage('B��d podczas �adowania produkt�w: ' + E.Message);
    end;

  finally
    FQuery.Close; // Zamykanie bez wzgl�du na wynik
  end;
end;




(* Wirtualizacja (Lazy Loading) w TStringGrid dla FMX *)
procedure TDatabaseManager.LoadProductsLazy(Grid: TStringGrid; PageSize: Integer);
var
  i, j: Integer;
  Field: TField;
  Col: TStringColumn;
begin
  try
    // Je�li nie ma jeszcze kolumn, dodaj je dynamicznie

    Grid.ClearColumns;
    //if Grid.ColumnCount = 0 then
    begin
      FQuery.SQL.Text := 'SELECT * FROM Product LIMIT 1;'; // Pobierz tylko jedn� lini�, aby okre�li� struktur�
      FQuery.Open;

      // Usuni�cie istniej�cych kolumn

      for j := 0 to FQuery.FieldCount - 1 do
      begin
        Col := TStringColumn.Create(Grid);
        Col.Header := FQuery.Fields[j].FieldName; // Nag��wek kolumny
        Col.Width := 100;
        Grid.AddObject(Col);
      end;
      Grid.Columns[0].Width := 50;
      FQuery.Close;
    end;

    // Zapytanie z paginacj�
    FQuery.SQL.Text := Format(
      'SELECT * FROM Product ORDER BY timestamp DESC LIMIT %d OFFSET %d;',
      [PageSize, Grid.RowCount]
    );
    FQuery.Open;

    // Dodanie nowych wierszy do StringGrid
    while not FQuery.Eof do
    begin
      Grid.RowCount := Grid.RowCount + 1;
      for j := 0 to FQuery.FieldCount - 1 do
      begin
        // Zabezpieczenie przed indeksem poza zakresem kolumny
        if j < Grid.ColumnCount then
        begin
          Field := FQuery.Fields[j];
          Grid.Cells[j, Grid.RowCount - 1] := Field.AsString;
        end;
      end;
      FQuery.Next;
    end;

    FQuery.Close;
  except
    on E: Exception do
      ShowMessage('B��d podczas �adowania produkt�w: ' + E.Message);
  end;
end;







(* Dodawanie nowego produktu *)
procedure TDatabaseManager.InsertProduct(Length, Diameter, Width, Height, Volume: Real; Quantity, Pack_id, Tree_id, Quality_id : Integer);
begin
    try

        // Sprawdzenie, czy FQuery jest zainicjowane
        if FQuery = nil then
          raise Exception.Create('FQuery nie zainicjalizowane podczas dodawania produktu');

        // Sprawdzenie, czy FQuery ma po��czenie
        if FQuery.Connection = nil then
          raise Exception.Create('Brak po��czenia w FQuery podczas dodawania produktu');

        FQuery.SQL.Text := 'INSERT INTO Product (length, diameter, width, height, volume, quantity, pack_id, tree_id, quality_id) VALUES (:L, :D, :W, :H, :V, :Q, :PID, :TID, :QID);';
        FQuery.ParamByName('L').AsFloat := Length;
        FQuery.ParamByName('D').AsFloat := Diameter;
        FQuery.ParamByName('W').AsFloat := Width;
        FQuery.ParamByName('H').AsFloat := Height;
        FQuery.ParamByName('V').AsFloat := Volume;
        FQuery.ParamByName('Q').AsInteger := Quantity;


        // Ustawienie typu i warto�ci dla parametru :PID
        FQuery.ParamByName('PID').DataType := ftInteger;
        if (Pack_id > 0) then
          FQuery.ParamByName('PID').AsInteger := Pack_id
        else
          FQuery.ParamByName('PID').Clear;

        // Ustawienie typu i warto�ci dla parametru :TID
        FQuery.ParamByName('TID').DataType := ftInteger;
        if (Tree_id > 0) then
          FQuery.ParamByName('TID').AsInteger := Tree_id
        else
          FQuery.ParamByName('TID').Clear;

        // Ustawienie typu i warto�ci dla parametru :QID
        FQuery.ParamByName('QID').DataType := ftInteger;
        if (Quality_id > 0) then
          FQuery.ParamByName('QID').AsInteger := Quality_id
        else
          FQuery.ParamByName('QID').Clear;

        FQuery.ExecSQL;

    except
        on E: Exception do
          ShowMessage('B��d podczas dodawania produktu: ' + E.Message);
    end;

end;

end.

