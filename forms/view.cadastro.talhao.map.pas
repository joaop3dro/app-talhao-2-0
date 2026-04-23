unit view.cadastro.talhao.map;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Permissions, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Edit, FMX.Memo, FMX.Ani, FMX.Memo.Types,
  FMX.Maps,
  System.Sensors, System.Sensors.Components,
  models, FMX.ScrollBox, FMX.DialogService;

type
  TViewCadastroTalhaoMap = class(TForm)
    rectHeader: TRectangle;
    btnVoltar: TButton;
    lblTitulo: TLabel;
    btnSalvar: TButton;
    rectInfoBar: TRectangle;
    lblPontos: TLabel;
    lblPerimetro: TLabel;
    lblArea: TLabel;
    mapView: TMapView;
    rectToolbar: TRectangle;
    btnDesfazer: TButton;
    btnLimpar: TButton;
    btnFecharPoly: TButton;
    btnGPS: TButton;
    rectPainelDados: TRectangle;
    layoutDados: TLayout;
    edtNome: TEdit;
    edtGrupo: TEdit;
    memoDescricao: TMemo;
    locSensor: TLocationSensor;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnVoltarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnDesfazerClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure btnFecharPolyClick(Sender: TObject);
    procedure btnGPSClick(Sender: TObject);
    procedure mapViewMapClick(const Position: TMapCoordinate);
    procedure mapViewMarkerDragStart(const Marker: TMapMarker);
    procedure mapViewMarkerDragEnd(const Marker: TMapMarker);
    procedure locSensorLocationChanged(Sender: TObject;
      const OldLocation, NewLocation: TLocationCoord2D);

  private
    FTalhao: TTalhao;
    FModoEdicao: Boolean;
    FModoSoLeitura: Boolean;         // Modo consulta: sem pings, sem edicao
    FPolyline: TMapPolyline;
    FPolygon: TMapPolygon;
    FMarkers: TList<TMapMarker>;     // Vertices arrastaveis
    FDistMarkers: TList<TMapMarker>; // Labels de distancia por segmento
    FPoligonFechado: Boolean;
    FPrimeiraLocalizacao: Boolean;
    FArrastando: Boolean;

    procedure LimparMapa;
    procedure DesenharPolyline;
    procedure FecharPoligono;
    procedure AtualizarInfoBar;
    procedure CentralizarMapa(const ALat, ALng: Double);
    procedure AdicionarMarcador(const ALat, ALng: Double);
    procedure AtualizarMarcadoresDistancia; // Feature 1: distancia por segmento
    procedure RemoverMarcadoresDistancia;
    function  HaversineKm(const P1, P2: TGeoPoint): Double;
    procedure SolicitarPermissaoLocalizacao;
    function ValidarDados: Boolean;
  public
    procedure CarregarTalhaoExistente(ATalhao: TTalhao);
    procedure CarregarTalhaoSoLeitura(ATalhao: TTalhao); // Feature 2: sem pings
  end;

var
  ViewCadastroTalhaoMap: TViewCadastroTalhaoMap;

implementation

{$R *.fmx}

uses System.Math, System.StrUtils, model.con;

procedure TViewCadastroTalhaoMap.FormCreate(Sender: TObject);
begin
  FTalhao          := TTalhao.Create;
  FModoEdicao      := False;
  FModoSoLeitura   := False;
  FPolyline        := nil;
  FPolygon         := nil;
  FMarkers         := TList<TMapMarker>.Create;
  FDistMarkers     := TList<TMapMarker>.Create;
  FPoligonFechado  := False;
  FPrimeiraLocalizacao := True;
  FArrastando      := False;

  mapView.OnMapClick        := mapViewMapClick;
  mapView.MapType := TMapType.Satellite;
  mapView.Zoom    := 4;
  mapView.Location := TMapCoordinate.Create(-15.7801, -47.9292); // Brasil

  locSensor.Active := False;
  locSensor.OnLocationChanged := locSensorLocationChanged;
end;

procedure TViewCadastroTalhaoMap.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TViewCadastroTalhaoMap.FormDestroy(Sender: TObject);
begin
  locSensor.Active := False;
  FDistMarkers.Free;
  FMarkers.Free;
  FTalhao.Free;
end;

procedure TViewCadastroTalhaoMap.FormShow(Sender: TObject);
var
  i: Integer;
begin
  AtualizarInfoBar;

  // Feature 2: modo so leitura — exibe poligono sem pings, oculta edicao
  if FModoSoLeitura then
  begin
    rectToolbar.Visible     := False;
    rectPainelDados.Visible := False;
    btnSalvar.Visible       := False;
    if FTalhao.Pontos.Count > 0 then
    begin
      FecharPoligono;
      CentralizarMapa(FTalhao.Pontos[0].Latitude, FTalhao.Pontos[0].Longitude);
    end;
    Exit;
  end;

  SolicitarPermissaoLocalizacao;

  if FModoEdicao and (FTalhao.Pontos.Count > 0) then
  begin
    for i := 0 to FTalhao.Pontos.Count - 1 do
      AdicionarMarcador(FTalhao.Pontos[i].Latitude, FTalhao.Pontos[i].Longitude);

    FecharPoligono;
    CentralizarMapa(FTalhao.Pontos[0].Latitude, FTalhao.Pontos[0].Longitude);
  end;
end;

procedure TViewCadastroTalhaoMap.SolicitarPermissaoLocalizacao;
begin
  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    ['android.permission.ACCESS_FINE_LOCATION',
     'android.permission.ACCESS_COARSE_LOCATION'],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) > 0) and
         (AGrantResults[0] = TPermissionStatus.Granted) then
        locSensor.Active := True;
    end,
    nil
  );
  {$ELSE}
  locSensor.Active := True;
  {$ENDIF}
end;

procedure TViewCadastroTalhaoMap.locSensorLocationChanged(Sender: TObject;
  const OldLocation, NewLocation: TLocationCoord2D);
begin
  if FPrimeiraLocalizacao and not FModoEdicao then
  begin
    FPrimeiraLocalizacao := False;
    CentralizarMapa(NewLocation.Latitude, NewLocation.Longitude);
    locSensor.Active := False;
  end;
end;

procedure TViewCadastroTalhaoMap.CentralizarMapa(const ALat, ALng: Double);
begin
  mapView.Location := TMapCoordinate.Create(ALat, ALng);
  mapView.Zoom := 16;
end;

procedure TViewCadastroTalhaoMap.mapViewMapClick(const Position: TMapCoordinate);
var
  GP: TGeoPoint;
begin
  // Ignora click se polígono fechado ou se está arrastando marcador
  if FPoligonFechado or FArrastando or FModoSoLeitura then
    Exit;

  GP.Latitude  := Position.Latitude;
  GP.Longitude := Position.Longitude;
  FTalhao.Pontos.Add(GP);

  AdicionarMarcador(Position.Latitude, Position.Longitude);
  DesenharPolyline;
  FTalhao.CalcularAreaEPerimetro;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.AdicionarMarcador(const ALat, ALng: Double);
var
  LDesc: TMapMarkerDescriptor;
  LMarker: TMapMarker;
begin
  LDesc := TMapMarkerDescriptor.Create(
    TMapCoordinate.Create(ALat, ALng),
    Format('P%d', [FMarkers.Count + 1])
  );
  LDesc.Draggable := True;

  LMarker := mapView.AddMarker(LDesc);
  FMarkers.Add(LMarker);
end;

procedure TViewCadastroTalhaoMap.mapViewMarkerDragStart(const Marker: TMapMarker);
begin
  FArrastando := True;
end;

procedure TViewCadastroTalhaoMap.mapViewMarkerDragEnd(const Marker: TMapMarker);
var
  i: Integer;
  GP: TGeoPoint;
begin
  FArrastando := False;

  for i := 0 to FMarkers.Count - 1 do
  begin
    if FMarkers[i] = Marker then
    begin
      if i < FTalhao.Pontos.Count then
      begin
        GP.Latitude  := Marker.Descriptor.Position.Latitude;
        GP.Longitude := Marker.Descriptor.Position.Longitude;
        FTalhao.Pontos[i] := GP;
      end;
      Break;
    end;
  end;

  if FPoligonFechado then
  begin
    if Assigned(FPolygon) then FPolygon.Remove;
    FPolygon := nil;
    FPoligonFechado := False;
    FecharPoligono; // Redesenha + AtualizarMarcadoresDistancia
  end
  else
    DesenharPolyline; // Inclui AtualizarMarcadoresDistancia

  FTalhao.CalcularAreaEPerimetro;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.DesenharPolyline;
var
  LPts: TArray<TMapCoordinate>;
  LDesc: TMapPolylineDescriptor;
  i: Integer;
begin
  if Assigned(FPolyline) then
  begin
    FPolyline.Remove;
    FPolyline := nil;
  end;

  if FTalhao.Pontos.Count < 2 then
    Exit;

  SetLength(LPts, FTalhao.Pontos.Count);
  for i := 0 to FTalhao.Pontos.Count - 1 do
    LPts[i] := TMapCoordinate.Create(
      FTalhao.Pontos[i].Latitude,
      FTalhao.Pontos[i].Longitude
    );

  LDesc := TMapPolylineDescriptor.Create(LPts);
  LDesc.StrokeColor := TAlphaColorRec.Orangered;
  LDesc.StrokeWidth := 3;

  FPolyline := mapView.AddPolyline(LDesc);

  AtualizarMarcadoresDistancia; // Feature 1: distancia em cada segmento
end;

procedure TViewCadastroTalhaoMap.FecharPoligono;
var
  LPts: TArray<TMapCoordinate>;
  LDesc: TMapPolygonDescriptor;
  i: Integer;
begin
  if FTalhao.Pontos.Count < 3 then
  begin
    TDialogService.ShowMessage('Adicione pelo menos 3 pontos para fechar o talhão.');
    Exit;
  end;
  if FPoligonFechado then Exit;

  // Remove polyline aberta
  if Assigned(FPolyline) then
  begin
    FPolyline.Remove;
    FPolyline := nil;
  end;

  // Monta array de coordenadas
  SetLength(LPts, FTalhao.Pontos.Count);
  for i := 0 to FTalhao.Pontos.Count - 1 do
    LPts[i] := TMapCoordinate.Create(
      FTalhao.Pontos[i].Latitude,
      FTalhao.Pontos[i].Longitude
    );

  // Cria o polígono — construtor recebe o array de pontos
  LDesc := TMapPolygonDescriptor.Create(LPts);
  LDesc.StrokeColor := TAlphaColorRec.Orangered;
  LDesc.StrokeWidth := 3;
  LDesc.FillColor   := $60F57F17; // Laranja 38% opac.

  FPolygon := mapView.AddPolygon(LDesc);
  FPoligonFechado := True;

  AtualizarMarcadoresDistancia; // Feature 1: distancia nos segmentos do poligono

  FTalhao.CalcularAreaEPerimetro;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.LimparMapa;
var
  i: Integer;
begin
  RemoverMarcadoresDistancia; // Feature 1: remove labels de distancia

  if Assigned(FPolyline) then
  begin
    FPolyline.Remove;
    FPolyline := nil;
  end;

  if Assigned(FPolygon)  then
  begin
    FPolygon.Remove;
    FPolygon  := nil;
  end;

  for i := 0 to FMarkers.Count - 1 do
    if Assigned(FMarkers[i]) then
      FMarkers[i].Remove;

  FMarkers.Clear;

  FTalhao.Pontos.Clear;
  FTalhao.Area := 0;
  FTalhao.Perimetro := 0;
  FPoligonFechado := False;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.AtualizarInfoBar;
begin
  lblPontos.Text    := Format('%d pontos', [FTalhao.Pontos.Count]);
  lblPerimetro.Text := Format('Perimetro: %.2f km', [FTalhao.Perimetro]);
  lblArea.Text      := Format('Area: %.2f ha', [FTalhao.Area]);
end;

procedure TViewCadastroTalhaoMap.CarregarTalhaoExistente(ATalhao: TTalhao);
begin
  FTalhao.Free;
  FTalhao        := ATalhao;
  FModoEdicao    := True;
  FModoSoLeitura := False;
  lblTitulo.Text := 'Editar Talhao';
  edtNome.Text   := FTalhao.Nome;
  edtGrupo.Text  := FTalhao.Grupo;
  memoDescricao.Lines.Text := FTalhao.Descricao;
  AtualizarInfoBar;
end;

// Feature 2: carrega talhao sem pings (modo consulta/visualizacao)
procedure TViewCadastroTalhaoMap.CarregarTalhaoSoLeitura(ATalhao: TTalhao);
begin
  FTalhao.Free;
  FTalhao        := ATalhao;
  FModoEdicao    := True;
  FModoSoLeitura := True;
  lblTitulo.Text := ATalhao.Nome;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.btnVoltarClick(Sender: TObject);
begin
  if FTalhao.Pontos.Count > 0 then
  begin
    TDialogService.MessageDialog('Deseja sair sem salvar?',
      TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        if AResult = mrYes then
          Close;
      end);
  end
  else
    Close;
end;

procedure TViewCadastroTalhaoMap.btnSalvarClick(Sender: TObject);
begin
  if not ValidarDados then Exit;
  FTalhao.Nome      := edtNome.Text.Trim;
  FTalhao.Grupo     := edtGrupo.Text.Trim;
  FTalhao.Descricao := memoDescricao.Lines.Text.Trim;
  try
    if FModoEdicao then
      dmCon.AtualizarTalhao(FTalhao)
    else
      dmCon.SalvarTalhao(FTalhao);

    TDialogService.ShowMessage('Talhao salvo com sucesso!',
      procedure(const AResult: TModalResult)
      begin
        ModalResult := mrOk;
        Close;
      end);
  except
    on E: Exception do TDialogService.ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TViewCadastroTalhaoMap.btnDesfazerClick(Sender: TObject);
var
  LUlt: TMapMarker;
begin
  if FTalhao.Pontos.Count = 0 then
    Exit;

  if FPoligonFechado then
  begin
    TDialogService.ShowMessage('Poligono ja fechado. Use Limpar para recomecar.');
    Exit;
  end;

  FTalhao.Pontos.Delete(FTalhao.Pontos.Count - 1);

  if FMarkers.Count > 0 then
  begin
    LUlt := FMarkers.Last;
    LUlt.Remove;
    FMarkers.Delete(FMarkers.Count - 1);
  end;

  DesenharPolyline; // Inclui AtualizarMarcadoresDistancia
  FTalhao.CalcularAreaEPerimetro;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhaoMap.btnLimparClick(Sender: TObject);
begin
  TDialogService.MessageDialog('Limpar todos os pontos?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
        LimparMapa;
    end);
end;

procedure TViewCadastroTalhaoMap.btnFecharPolyClick(Sender: TObject);
begin
  FecharPoligono;
end;

procedure TViewCadastroTalhaoMap.btnGPSClick(Sender: TObject);
begin
  FPrimeiraLocalizacao := True;
  SolicitarPermissaoLocalizacao;

  if not locSensor.Active then
    locSensor.Active := True;
end;

function TViewCadastroTalhaoMap.ValidarDados: Boolean;
begin
  Result := False;

  if edtNome.Text.Trim = '' then
  begin
    TDialogService.ShowMessage('Informe o nome do talhao.');
    edtNome.SetFocus;
    Exit;
  end;

  if not FPoligonFechado then
  begin
    TDialogService.ShowMessage('Feche o poligono antes de salvar.');
    Exit;
  end;

  if FTalhao.Pontos.Count < 3 then
  begin
    TDialogService.ShowMessage('O talhao precisa ter pelo menos 3 pontos.');
    Exit;
  end;

  Result := True;
end;

function TViewCadastroTalhaoMap.HaversineKm(const P1, P2: TGeoPoint): Double;
const
  R = 6371.0;
  DEG2RAD = PI / 180.0;
var
  dLat, dLon, A, C: Double;
begin
  dLat := (P2.Latitude  - P1.Latitude)  * DEG2RAD;
  dLon := (P2.Longitude - P1.Longitude) * DEG2RAD;
  A := Sin(dLat/2)*Sin(dLat/2) +
       Cos(P1.Latitude*DEG2RAD) * Cos(P2.Latitude*DEG2RAD) *
       Sin(dLon/2)*Sin(dLon/2);
  C := 2 * ArcTan2(Sqrt(A), Sqrt(1 - A));
  Result := R * C;
end;

procedure TViewCadastroTalhaoMap.RemoverMarcadoresDistancia;
var
  i: Integer;
begin
  for i := 0 to FDistMarkers.Count - 1 do
    if Assigned(FDistMarkers[i]) then
      FDistMarkers[i].Remove;
  FDistMarkers.Clear;
end;

procedure TViewCadastroTalhaoMap.AtualizarMarcadoresDistancia;
var
  i, N, LTotal: Integer;
  P1, P2: TGeoPoint;
  MidLat, MidLng, DistKm: Double;
  LCoord: TMapCoordinate;
  LDesc: TMapMarkerDescriptor;
  LLabel: string;
begin
  RemoverMarcadoresDistancia;

  N := FTalhao.Pontos.Count;
  if N < 2 then Exit;

  // Poligono fechado: inclui segmento final Pn -> P0
  LTotal := IfThen(FPoligonFechado, N, N - 1);

  for i := 0 to LTotal - 1 do
  begin
    P1 := FTalhao.Pontos[i];
    P2 := FTalhao.Pontos[(i + 1) mod N];

    // Ponto medio do segmento
    MidLat := (P1.Latitude  + P2.Latitude)  / 2;
    MidLng := (P1.Longitude + P2.Longitude) / 2;

    DistKm := HaversineKm(P1, P2);

    // Exibe em metros se < 1 km, em km caso contrario
    if DistKm < 1.0 then
      LLabel := Format('%.0fm', [DistKm * 1000])
    else
      LLabel := Format('%.2fkm', [DistKm]);

    LCoord.Latitude  := MidLat;
    LCoord.Longitude := MidLng;

    LDesc := TMapMarkerDescriptor.Create(LCoord, LLabel);
    LDesc.Draggable := False; // Marcador de distancia nao e arrastaval

    FDistMarkers.Add(mapView.AddMarker(LDesc));
  end;
end;


end.
