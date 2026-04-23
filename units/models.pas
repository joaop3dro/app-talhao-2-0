unit models;

interface

uses
  System.Classes, System.Generics.Collections, System.SysUtils;

type
  // Representa um ponto geográfico (lat/lng)
  TGeoPoint = record
    Latitude: Double;
    Longitude: Double;
    constructor Create(ALat, ALng: Double);
    function ToString: string;
  end;

  // Lista de pontos geográficos
  TGeoPointList = TList<TGeoPoint>;

  // Modelo principal do Talhão
  TTalhao = class
  private
    FId: Integer;
    FNome: string;
    FDescricao: string;
    FArea: Double;       // em hectares
    FPerimetro: Double;  // em km
    FGrupo: string;
    FDataCadastro: TDateTime;
    FPontos: TGeoPointList;
    function GetPontosJSON: string;
    procedure SetPontosJSON(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CalcularAreaEPerimetro;

    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Area: Double read FArea write FArea;
    property Perimetro: Double read FPerimetro write FPerimetro;
    property Grupo: string read FGrupo write FGrupo;
    property DataCadastro: TDateTime read FDataCadastro write FDataCadastro;
    property Pontos: TGeoPointList read FPontos;
    property PontosJSON: string read GetPontosJSON write SetPontosJSON;
  end;

  TTalhaoList = TObjectList<TTalhao>;

implementation

uses
  System.Math, System.JSON;

{ TGeoPoint }

constructor TGeoPoint.Create(ALat, ALng: Double);
begin
  Latitude := ALat;
  Longitude := ALng;
end;

function TGeoPoint.ToString: string;
begin
  Result := Format('%.8f,%.8f', [Latitude, Longitude]);
end;

{ TTalhao }

constructor TTalhao.Create;
begin
  inherited;
  FPontos := TGeoPointList.Create;
  FDataCadastro := Now;
  FArea := 0;
  FPerimetro := 0;
end;

destructor TTalhao.Destroy;
begin
  FPontos.Free;
  inherited;
end;

function TTalhao.GetPontosJSON: string;
var
  LArray: TJSONArray;
  LObj: TJSONObject;
  i: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for i := 0 to FPontos.Count - 1 do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('lat', TJSONNumber.Create(FPontos[i].Latitude));
      LObj.AddPair('lng', TJSONNumber.Create(FPontos[i].Longitude));
      LArray.AddElement(LObj);
    end;
    Result := LArray.ToJSON;
  finally
    LArray.Free;
  end;
end;

procedure TTalhao.SetPontosJSON(const AValue: string);
var
  LArray: TJSONArray;
  LObj: TJSONValue;
  LPoint: TGeoPoint;
begin
  FPontos.Clear;
  if AValue = '' then
    Exit;

  LArray := TJSONObject.ParseJSONValue(AValue) as TJSONArray;
  if not Assigned(LArray) then
    Exit;
  try
    for LObj in LArray do
    begin
      LPoint.Latitude  := (LObj as TJSONObject).GetValue<Double>('lat');
      LPoint.Longitude := (LObj as TJSONObject).GetValue<Double>('lng');
      FPontos.Add(LPoint);
    end;
  finally
    LArray.Free;
  end;
end;

procedure TTalhao.CalcularAreaEPerimetro;
// Algoritmo de Shoelace para área (em graus²) + conversão para hectares
// Haversine para perímetro em km
const
  R = 6371.0; // raio médio da Terra em km
  DEG_TO_RAD = PI / 180.0;

  function HaversineDist(p1, p2: TGeoPoint): Double;
  var
    dLat, dLon, a, c: Double;
  begin
    dLat := (p2.Latitude  - p1.Latitude)  * DEG_TO_RAD;
    dLon := (p2.Longitude - p1.Longitude) * DEG_TO_RAD;
    a := Sin(dLat/2)*Sin(dLat/2) +
         Cos(p1.Latitude*DEG_TO_RAD)*Cos(p2.Latitude*DEG_TO_RAD)*
         Sin(dLon/2)*Sin(dLon/2);
    c := 2 * ArcTan2(Sqrt(a), Sqrt(1-a));
    Result := R * c;
  end;

var
  i, n: Integer;
  AreaGraus, SomaLat: Double;
  p1, p2: TGeoPoint;
  AreaM2: Double;
begin
  n := FPontos.Count;
  if n < 3 then
  begin
    FArea := 0;
    FPerimetro := 0;
    Exit;
  end;

  // Área via Shoelace convertida para m²
  AreaGraus := 0;
  SomaLat := 0;
  for i := 0 to n - 1 do
  begin
    p1 := FPontos[i];
    p2 := FPontos[(i + 1) mod n];
    AreaGraus := AreaGraus + (p1.Longitude * p2.Latitude) - (p2.Longitude * p1.Latitude);
    SomaLat := SomaLat + p1.Latitude;
  end;

  AreaGraus := Abs(AreaGraus) / 2.0;
  // Conversão: 1 grau de lat ≈ 111320m, 1 grau lng ≈ 111320 * cos(lat_media)
  SomaLat := SomaLat / n;
  AreaM2 := AreaGraus *
             Power(111320.0, 2) *
             Cos(SomaLat * DEG_TO_RAD);
  FArea := AreaM2 / 10000.0; // m² -> hectares

  // Perímetro via Haversine
  FPerimetro := 0;
  for i := 0 to n - 1 do
  begin
    p1 := FPontos[i];
    p2 := FPontos[(i + 1) mod n];
    FPerimetro := FPerimetro + HaversineDist(p1, p2);
  end;
end;

end.
