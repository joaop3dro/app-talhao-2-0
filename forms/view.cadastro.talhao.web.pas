unit view.cadastro.talhao.web;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.WebBrowser,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.ListBox,
  FMX.Ani, FMX.Memo.Types,
  System.NetEncoding, System.IOUtils, FMX.DialogService,
  models, System.StrUtils, System.Math;

type
  TViewCadastroTalhao = class(TForm)
    rectRoot: TRectangle;
    rectHeader: TRectangle;
    btnVoltar: TButton;
    lblTitulo: TLabel;
    btnSalvar: TButton;
    rectInfoBar: TRectangle;
    lblPerimetro: TLabel;
    lblArea: TLabel;
    lblPontos: TLabel;
    webMap: TWebBrowser;
    rectPainelDados: TRectangle;
    layoutDados: TLayout;
    edtNome: TEdit;
    edtGrupo: TEdit;
    memoDescricao: TMemo;
    rectToolbar: TRectangle;
    btnDesfazer: TButton;
    btnLimpar: TButton;
    btnLocalizar: TButton;
    btnFecharPoly: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnVoltarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnDesfazerClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure btnLocalizarClick(Sender: TObject);
    procedure btnFecharPolyClick(Sender: TObject);
    procedure webMapShouldStartLoadWithRequest(ASender: TObject;
      const URL: string);

  private
    FTalhao: TTalhao;
    FModoEdicao: Boolean;
    FPainelVisivel: Boolean;
    FArquivoHTML: string;

    procedure CarregarHTML;
    procedure AtualizarInfoBar;
    procedure AtualizarMapaComTalhao;
    procedure ProcessarEvento(const AAcao, ADados: string);
    procedure ExecutarJS(const AScript: string);
    procedure TogglePainelDados;
    function ValidarDados: Boolean;
  public
    procedure CarregarTalhaoExistente(ATalhao: TTalhao);
  end;

var
  ViewCadastroTalhao: TViewCadastroTalhao;

implementation

{$R *.fmx}

uses model.con;

const
  MAPS_API_KEY    = 'CHAVE_API_KEY';
  CALLBACK_SCHEME = 'talhaoapp';

function ObterMapaHTML: string;
begin
  Result :=
    '<!DOCTYPE html><html><head>' +
    '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">' +
    '<style>* { margin:0; padding:0; box-sizing:border-box; } html,body,#map { width:100%; height:100%; }</style>' +
    '</head><body><div id="map"></div><script>' +

    'var map, poly, markers=[], pontos=[], poligonoFechado=false;' +

    'function initMap(){' +
    '  map=new google.maps.Map(document.getElementById("map"),{' +
    '    zoom:4, center:{lat:-15.7801,lng:-47.9292},' +
    '    mapTypeId:"satellite", disableDefaultUI:true, gestureHandling:"greedy"' +
    '  });' +
    '  poly=new google.maps.Polyline({strokeColor:"#E65100",strokeOpacity:1,strokeWeight:3,map:map});' +
    '  map.addListener("click",function(e){' +
    '    if(poligonoFechado)return;' +
    '    adicionarPonto(e.latLng.lat(),e.latLng.lng());' +
    '  });' +
    '}' +

    'function adicionarPonto(lat,lng){' +
    '  pontos.push({lat:lat,lng:lng});' +
    '  poly.getPath().push(new google.maps.LatLng(lat,lng));' +
    '  var marker=new google.maps.Marker({' +
    '    position:{lat:lat,lng:lng},map:map,draggable:true,' +
    '    icon:{path:google.maps.SymbolPath.CIRCLE,scale:6,' +
    '      fillColor:"#E65100",fillOpacity:1,strokeColor:"#FFF",strokeWeight:2}' +
    '  });' +
    '  var idx=markers.length;' +
    '  marker.addListener("dragend",function(e){' +
    '    pontos[idx].lat=e.latLng.lat(); pontos[idx].lng=e.latLng.lng();' +
    '    redesenharPoly();' +
    '    notificarDelphi("update",JSON.stringify(pontos));' +
    '  });' +
    '  markers.push(marker);' +
    '  notificarDelphi("ponto",lat+"|"+lng+"|"+pontos.length);' +
    '}' +

    'function fecharPoligono(){' +
    '  if(pontos.length<3){alert("Adicione pelo menos 3 pontos.");return;}' +
    '  if(poligonoFechado)return;' +
    '  poligonoFechado=true;' +
    '  poly.setMap(null);' +
    '  window._polygon=new google.maps.Polygon({paths:pontos,' +
    '    strokeColor:"#E65100",strokeOpacity:1,strokeWeight:3,' +
    '    fillColor:"#F57F17",fillOpacity:0.35,map:map});' +
    '  notificarDelphi("fechado",JSON.stringify(pontos));' +
    '}' +

    'function desfazerUltimoPonto(){' +
    '  if(pontos.length===0)return;' +
    '  pontos.pop();' +
    '  var u=markers.pop(); if(u)u.setMap(null);' +
    '  redesenharPoly();' +
    '  notificarDelphi("desfazer",pontos.length.toString());' +
    '}' +

    'function limparTudo(){' +
    '  pontos=[]; markers.forEach(function(m){m.setMap(null);}); markers=[];' +
    '  if(window._polygon){window._polygon.setMap(null);window._polygon=null;}' +
    '  poly.setPath([]); poly.setMap(map); poligonoFechado=false;' +
    '  notificarDelphi("limpar","0");' +
    '}' +

    'function redesenharPoly(){' +
    '  var c=[]; pontos.forEach(function(p){c.push(new google.maps.LatLng(p.lat,p.lng));});' +
    '  poly.setPath(c);' +
    '}' +

    'function centralizarMapa(lat,lng){map.setCenter({lat:lat,lng:lng});map.setZoom(16);}' +

    'function carregarPontos(jsonStr){' +
    '  limparTudo();' +
    '  var pts=JSON.parse(jsonStr);' +
    '  pts.forEach(function(p){adicionarPonto(p.lat,p.lng);});' +
    '  fecharPoligono();' +
    '  if(pts.length>0)centralizarMapa(pts[0].lat,pts[0].lng);' +
    '}' +
    'function notificarDelphi(acao,dados){' +
    '  try{' +
    '    var f=document.createElement("iframe");' +
    '    f.style.display="none";' +
    '    f.src="talhaoapp://"+acao+"/"+encodeURIComponent(dados);' +
    '    document.body.appendChild(f);' +
    '    setTimeout(function(){if(f.parentNode)f.parentNode.removeChild(f);},150);' +
    '  }catch(ex){}' +
    '}' +

    '</script>' +
    '<script async defer src="https://maps.googleapis.com/maps/api/js?key=' +
    MAPS_API_KEY + '&callback=initMap"></script>' +
    '</body></html>';
end;

procedure TViewCadastroTalhao.FormCreate(Sender: TObject);
begin
  FTalhao := TTalhao.Create;
  FModoEdicao := False;
  FPainelVisivel := True;
  FArquivoHTML := '';
  webMap.OnShouldStartLoadWithRequest := webMapShouldStartLoadWithRequest;
end;

procedure TViewCadastroTalhao.FormDestroy(Sender: TObject);
begin
  FTalhao.Free;

  if (FArquivoHTML <> '') and FileExists(FArquivoHTML) then
    TFile.Delete(FArquivoHTML);
end;

procedure TViewCadastroTalhao.FormShow(Sender: TObject);
begin
  CarregarHTML;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhao.CarregarHTML;
var
  LDir, LURL: string;
begin
  {$IFDEF MSWINDOWS}
  LDir := ExtractFilePath(ParamStr(0));
  {$ELSE}
  LDir := IncludeTrailingPathDelimiter(TPath.GetDocumentsPath);
  {$ENDIF}

  FArquivoHTML := LDir + 'talhaomap.html';

  with TStringList.Create do
  try
    Text := ObterMapaHTML;
    SaveToFile(FArquivoHTML, TEncoding.UTF8);
  finally
    Free;
  end;

  if not FileExists(FArquivoHTML) then
  begin
    TDialogService.ShowMessage('Nao foi possivel criar o arquivo do mapa. Caminho: ' + FArquivoHTML);
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  LURL := 'file:///' + StringReplace(FArquivoHTML, Chr(92), '/', [rfReplaceAll]);
  {$ELSE}
  LURL := 'file://' + FArquivoHTML;
  {$ENDIF}

  webMap.Navigate(LURL);
end;

procedure TViewCadastroTalhao.webMapShouldStartLoadWithRequest(ASender: TObject;
  const URL: string);
var
  LCaminho: string;
  LPartes: TArray<string>;
begin
  if not URL.StartsWith(CALLBACK_SCHEME + '://', True) then
    Exit;

  LCaminho := URL.Substring(Length(CALLBACK_SCHEME) + 3);
  LPartes  := LCaminho.Split(['/'], 2);

  ProcessarEvento(
    IfThen(Length(LPartes) >= 1, LPartes[0], ''),
    IfThen(Length(LPartes) >= 2, TNetEncoding.URL.Decode(LPartes[1]), '')
  );
end;

procedure TViewCadastroTalhao.ProcessarEvento(const AAcao, ADados: string);
var
  LPartes: TArray<string>;
  GP: TGeoPoint;
begin
  if AAcao = 'ponto' then
  begin
    LPartes := ADados.Split(['|']);
    if Length(LPartes) >= 2 then
    begin
      GP.Latitude  := StrToFloatDef(StringReplace(LPartes[0], ',', '.', []), 0);
      GP.Longitude := StrToFloatDef(StringReplace(LPartes[1], ',', '.', []), 0);
      FTalhao.Pontos.Add(GP);
      FTalhao.CalcularAreaEPerimetro;
      AtualizarInfoBar;
    end;
  end
  else if AAcao = 'desfazer' then
  begin
    if FTalhao.Pontos.Count > 0 then
      FTalhao.Pontos.Delete(FTalhao.Pontos.Count - 1);
    FTalhao.CalcularAreaEPerimetro;
    AtualizarInfoBar;
  end
  else if AAcao = 'limpar' then
  begin
    FTalhao.Pontos.Clear;
    FTalhao.Area := 0;
    FTalhao.Perimetro := 0;
    AtualizarInfoBar;
  end
  else if (AAcao = 'fechado') or (AAcao = 'update') then
  begin
    FTalhao.PontosJSON := ADados;
    FTalhao.CalcularAreaEPerimetro;
    AtualizarInfoBar;
  end;
end;

procedure TViewCadastroTalhao.AtualizarInfoBar;
begin
  lblPontos.Text    := Format('%d pontos', [FTalhao.Pontos.Count]);
  lblPerimetro.Text := Format('Perímetro: %.2f km', [FTalhao.Perimetro]);
  lblArea.Text      := Format('Área: %.2f ha', [FTalhao.Area]);
end;

procedure TViewCadastroTalhao.ExecutarJS(const AScript: string);
begin
  webMap.EvaluateJavaScript(AScript);
end;

procedure TViewCadastroTalhao.CarregarTalhaoExistente(ATalhao: TTalhao);
begin
  FTalhao.Free;
  FTalhao := ATalhao;
  FModoEdicao := True;
  lblTitulo.Text := 'Editar Talhão';
  edtNome.Text   := FTalhao.Nome;
  edtGrupo.Text  := FTalhao.Grupo;
  memoDescricao.Lines.Text := FTalhao.Descricao;
  AtualizarInfoBar;
end;

procedure TViewCadastroTalhao.AtualizarMapaComTalhao;
begin
  if FModoEdicao and (FTalhao.Pontos.Count > 0) then
    ExecutarJS(Format('carregarPontos(''%s'');', [FTalhao.PontosJSON]));
end;

procedure TViewCadastroTalhao.btnVoltarClick(Sender: TObject);
begin
  if FTalhao.Pontos.Count > 0 then
  begin
    TDialogService.MessageDialog('Deseja sair sem salvar?',
      TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        if AResult = mrYes then Close;
      end);
  end
  else
    Close;
end;

procedure TViewCadastroTalhao.btnSalvarClick(Sender: TObject);
begin
  if not ValidarDados then
    Exit;

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
    ModalResult := mrOk;
  except
    on E: Exception do
      TDialogService.ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TViewCadastroTalhao.btnDesfazerClick(Sender: TObject);
begin
  ExecutarJS('desfazerUltimoPonto();');
end;

procedure TViewCadastroTalhao.btnLimparClick(Sender: TObject);
begin
  TDialogService.MessageDialog('Limpar todos os pontos?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
        ExecutarJS('limparTudo();');
    end);
end;

procedure TViewCadastroTalhao.btnLocalizarClick(Sender: TObject);
begin
  ExecutarJS(
    'if(navigator.geolocation){' +
    '  navigator.geolocation.getCurrentPosition(function(p){' +
    '    centralizarMapa(p.coords.latitude,p.coords.longitude);' +
    '  });' +
    '}'
  );
end;

procedure TViewCadastroTalhao.btnFecharPolyClick(Sender: TObject);
begin
  ExecutarJS('fecharPoligono();');
end;

procedure TViewCadastroTalhao.TogglePainelDados;
var
  Anim: TFloatAnimation;
begin
  FPainelVisivel := not FPainelVisivel;
  Anim := TFloatAnimation.Create(rectPainelDados);
  Anim.Parent := rectPainelDados;
  Anim.PropertyName := 'Height';
  Anim.StartValue := rectPainelDados.Height;
  Anim.StopValue := IfThen(FPainelVisivel, 200, 0);
  Anim.Duration := 0.25;
  Anim.Start;
end;

function TViewCadastroTalhao.ValidarDados: Boolean;
begin
  Result := False;

  if edtNome.Text.Trim = '' then
  begin
    TDialogService.ShowMessage('Informe o nome do talhao.');
    edtNome.SetFocus;
    Exit;
  end;

  if FTalhao.Pontos.Count < 3 then
  begin
    TDialogService.ShowMessage('Desenhe o talhao com pelo menos 3 pontos.');
    Exit;
  end;

  Result := True;
end;

end.
