unit MainUnit;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.Edit,
  FMX.Layouts,
  FMX.Header,
  FMX.StdCtrls,
  System.Rtti,
  FMX.Grid.Style,
  FMX.Grid,
  FMX.ScrollBox,
  System.Skia,
  FMX.Skia,
  FMX.ListBox,
  FMX.ImgList,
  System.ImageList,
  FMX.Objects,
  FMX.Platform,

  FMX.Helpers.Android,
  FMX.VirtualKeyboard,
  Androidapi.JNI.Os,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Widget,
  Androidapi.JNI.InputMethodService,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.JNIBridge,
  Androidapi.JNI.Util,

  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.UI.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.FMXUI.Wait,
  FireDAC.Comp.UI,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  System.IOUtils,

  DataBaseManagerUnit, // Modu≥ z menedøerem bazy danych
  AppSettingsUnit, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView;     // Modu≥ z ustawieniami aplikacji



type
  TMainForm = class(TForm)
    GridPanelLayout1: TGridPanelLayout;
    edtL: TEdit;
    edtFi: TEdit;
    edtOut: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ToolBar1: TToolBar;
    Button1: TButton;
    Label5: TLabel;
    Label6: TLabel;
    StyleBook1: TStyleBook;
    Button2: TButton;
    GridPanelLayout2: TGridPanelLayout;
    ImageList1: TImageList;
    icon1: TGlyph;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    GridPanelLayout3: TGridPanelLayout;
    Image1: TImage;
    ListView1: TListView;

    function CalcValue(): Real;
    procedure edtFiChangeTracking(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Typing(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure StringGrid1ViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
    procedure GridPanelLayout3Click(Sender: TObject);


  private
    DatabaseManager: TDatabaseManager;
    DataSource: string;

    procedure CheckVirtualKeyboard;
    procedure GetCurrentInputMethod;
    procedure CheckInputMethod;
    procedure BluetoothDeviceDataReceived(const Data: string);


  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}






{************************** OBS£UGA FORMULARZA *****************************}




(* Stworzenie formularza *)
procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Naprawa komponentÛw na formularzu
  edtOut.Parent := nil;
  edtOut.Parent := GridPanelLayout1;
  GridPanelLayout1.ControlCollection[2].ColumnSpan := 2;

  StringGrid1.Parent := nil;
  StringGrid1.Parent := GridPanelLayout3;
  GridPanelLayout3.ControlCollection[0].ColumnSpan := 3;
  GridPanelLayout3.ControlCollection[0].RowSpan := 2;

  Button1.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  Button2.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  Button1.Position.X := MainForm.Width - Button1.Width - 10;
  Button2.Position.X := MainForm.Width - Button2.Width - 10;



  try
    // Tworzenie i konfiguracja menedøera bazy danych
    DatabaseManager := TDatabaseManager.Create;
    DatabaseManager.ConnectToDatabase;

    // Przekazanie menedøera bazy danych do klasy AppSettings
    TAppSettings.SetDatabaseManager(DatabaseManager);

    // Test zapisu ustawienia
    TAppSettings.Instance.SaveSetting('Language', 'PL');

    // Test odczytu ustawienia
    ShowMessage('Aktualny jÍzyk: ' + TAppSettings.Instance.GetSetting('Language', 'EN'));

    // Za≥adowanie tabeli
    //DatabaseManager.LoadProducts(StringGrid1);

    // Konfiguracja StringGrid
    StringGrid1.OnViewportPositionChange := StringGrid1ViewportPositionChange;
    StringGrid1.RowCount := 0; // Start bez wierszy

    // Za≥aduj pierwszπ partiÍ danych
    DatabaseManager.LoadProductsLazy(StringGrid1, 50);


  except
    on E: Exception do
    begin
      ShowMessage('B≥πd inicjalizacji: ' + E.Message);
     // Application.Terminate; // ZakoÒcz aplikacjÍ w razie krytycznego b≥Ídu
    end;
  end;
end;




(* Niszczenie formularza *)
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DatabaseManager.Free;
end;






{******************** OBS£UGA WERYFIKACJI èR”D£A DANYCH **********************}







(*  *)
procedure TMainForm.CheckVirtualKeyboard;
var
  KeyboardService: IFMXVirtualKeyboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(KeyboardService)) then
  begin
    if (KeyboardService <> nil) and (TVirtualKeyboardState.Visible in KeyboardService.VirtualKeyboardState) then
    begin
      // Klawiatura ekranowa jest aktywna
      DataSource := 'Keyboard';
    end;
  end;
end;


(*  *)
procedure TMainForm.GetCurrentInputMethod;
var
  InputMethodManager: JInputMethodManager;
  InputMethods: JList;
  InputMethodInfo: JInputMethodInfo;
  CurrentInputMethod: JComponentName;
  PackageName: string;
  I: Integer;
begin
  // Pobierz menedøera metod wejúcia
  InputMethodManager := TJInputMethodManager.Wrap(
    TAndroidHelper.Context.getSystemService(TJContext.JavaClass.INPUT_METHOD_SERVICE)
  );

  if InputMethodManager <> nil then
  begin
    // Lista dostÍpnych metod wprowadzania
    InputMethods := InputMethodManager.getEnabledInputMethodList;

    for I := 0 to InputMethods.size - 1 do
    begin
      // Pobierz informacje o metodzie wejúcia
      InputMethodInfo := TJInputMethodInfo.Wrap(InputMethods.get(I));

      // Pobierz nazwÍ pakietu
      PackageName := JStringToString(InputMethodInfo.getPackageName);
      ShowMessage(PackageName);
      // Sprawdü, czy pakiet naleøy do znanych klawiatur ekranowych
      if (PackageName.Contains('gboard')) or     // Google Gboard
         (PackageName.Contains('swiftkey')) or  // Microsoft SwiftKey
         (PackageName.Contains('samsung')) or   // Samsung Keyboard
         (PackageName.Contains('aosp')) then    // Android AOSP Keyboard
      begin
        ShowMessage('Wprowadzono dane za pomocπ klawiatury ekranowej.');
        Exit;
      end;
    end;

    // Jeúli øaden pakiet nie pasowa≥
    ShowMessage('Prawdopodobnie uøywasz klawiatury Bluetooth lub innego urzπdzenia.');
  end
  else
  begin
    ShowMessage('Brak dostÍpu do InputMethodManager.');
  end;
end;



procedure TMainForm.GridPanelLayout3Click(Sender: TObject);
begin

end;

(*  *)
procedure TMainForm.CheckInputMethod;
begin
    GetCurrentInputMethod;
end;


(*  *)
procedure TMainForm.Edit1Typing(Sender: TObject);
begin
    CheckInputMethod;
end;


(*  *)
procedure TMainForm.BluetoothDeviceDataReceived(const Data: string);
begin
  DataSource := 'Bluetooth';
end;







 {********************** LOGIKA APLIKACJI *************************}






(* Obliczenie wartoúci wed≥ug wybranej metody *)
procedure TMainForm.Button1Click(Sender: TObject);
var
  Length, Diameter, Width, Height, Volume: Real;
  Quantity, Pack_id, Tree_id, Quality_id: Integer;

begin
  // Przyk≥adowe dane (moøesz je zastπpiÊ danymi z pÛl edycyjnych lub innych ürÛde≥)
  Length := 10.5;
  Diameter := 5.2;
  Width := 7.0;
  Height := 12.3;
  Volume := 150.25;
  Quantity := 100;
  Pack_id := 0;
  Tree_id := 0;
  Quality_id := 0;


  try
    DatabaseManager.InsertProduct(Length, Diameter, Width, Height, Volume, Quantity, Pack_id, Tree_id, Quality_id);
  finally
    DatabaseManager.LoadProducts(StringGrid1);
  end;

end;








(*  *)
procedure TMainForm.Button2Click(Sender: TObject);
begin
  DatabaseManager.LoadProducts(StringGrid1);
end;





function TMainForm.CalcValue(): Real;
var
  L, Fi, factorL, factorFi: Real;
const
  PI = 3.14159265358979323846;
begin

  L := 0.0;
  Fi := 0.0;

  // konwersja do Real
  if (edtL.Text <> '') and (edtFi.Text <> '') then
  begin
    try
      L := StrToFloat(edtL.Text);
      Fi := StrToFloat(edtFi.Text);
    except
      on E: EConvertError do
        ShowMessage('B≥πd konwersji danych wejúciowych: ' + E.Message);
    end;

    // wybranie wspolczynnika do jednostki
    case 0 of
      0: factorL := 1.0;       // Metry
      1: factorL := 0.01;      // Centymetry
      2: factorL := 0.001;     // Milimetry
    end;

    case 1 of
      0: factorFi := 1.0;      // Metry
      1: factorFi := 0.01;     // Centymetry
      2: factorFi := 0.001;    // Milimetry
    end;

    Result := PI * Sqr((Fi*factorFi)/2) * (L*factorL);
  end
  else
    Result := 0.0;
end;




(* Wyzwalacz rekalkulacji objÍtoúci przy zmianie edtL / edtFi *)
procedure TMainForm.edtFiChangeTracking(Sender: TObject);
var
 out_val : Real;
begin
  out_val := CalcValue();
  edtOut.Text := FloatToStrF(out_val, ffFixed, 10, 4);;
end;





(* Obs≥uga przewijania i ≥adowania danych *)
procedure TMainForm.StringGrid1ViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  // Sprawdzenie, czy uøytkownik przewinπ≥ na sam dÛ≥
  if (NewViewportPosition.Y + StringGrid1.Height >= StringGrid1.ContentBounds.Height) then
  begin
    DatabaseManager.LoadProductsLazy(StringGrid1, 25); // Za≥aduj kolejne 50 rekordÛw
  end;
end;


end.
