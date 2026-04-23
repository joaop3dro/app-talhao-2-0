unit view.main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Ani, FMX.Effects,
  System.Skia, FMX.Skia;

type
  TfrmMain = class(TForm)
    rectBackground: TRectangle;
    rectHeader: TRectangle;
    lblAppTitle: TLabel;
    layoutButtons: TLayout;
    rectBtnCadastro: TRectangle;
    lblBtnCadastro: TLabel;
    rectBtnConsulta: TRectangle;
    lblBtnConsulta: TLabel;
    rectFooter: TRectangle;
    lblVersion: TLabel;
    Rectangle1: TRectangle;
    Label1: TLabel;
    imgLogo: TSkSvg;
    imgBtnCadastro: TSkSvg;
    imgBtnCadastroMapView: TSkSvg;
    imgBtnConsulta: TSkSvg;
    procedure FormCreate(Sender: TObject);
    procedure rectBtnCadastroClick(Sender: TObject);
    procedure rectBtnConsultaClick(Sender: TObject);
    procedure rectBtnCadastroMouseEnter(Sender: TObject);
    procedure rectBtnCadastroMouseLeave(Sender: TObject);
    procedure rectBtnConsultaMouseEnter(Sender: TObject);
    procedure rectBtnConsultaMouseLeave(Sender: TObject);
    procedure Rectangle1Click(Sender: TObject);
  private
    procedure ConfigurarUI;
    procedure AnimarEntrada;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  view.cadastro.talhao.map, view.cadastro.talhao.web, view.consulta.talhao;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ConfigurarUI;
  AnimarEntrada;
end;

procedure TfrmMain.Rectangle1Click(Sender: TObject);
var
  frm: TViewCadastroTalhaoMap;
begin
  frm := TViewCadastroTalhaoMap.Create(Application);
  try
    frm.Show;
  finally

  end;
end;

procedure TfrmMain.ConfigurarUI;
begin
  Self.Fill.Color := TAlphaColorRec.White;
  Self.Caption := 'Talhões';

  {$IFDEF ANDROID}
  Self.BorderStyle := TFmxFormBorderStyle.None;
  {$ENDIF}
  {$IFDEF IOS}
  Self.BorderStyle := TFmxFormBorderStyle.None;
  {$ENDIF}
end;

procedure TfrmMain.AnimarEntrada;
var
  Anim: TFloatAnimation;
begin
  if Assigned(layoutButtons) then
  begin
    layoutButtons.Opacity := 0;
    Anim := TFloatAnimation.Create(layoutButtons);
    Anim.Parent := layoutButtons;
    Anim.PropertyName := 'Opacity';
    Anim.StartValue := 0;
    Anim.StopValue := 1;
    Anim.Duration := 0.6;
    Anim.Delay := 0.3;
    Anim.Start;
  end;
end;

procedure TfrmMain.rectBtnCadastroClick(Sender: TObject);
var
  frm: TViewCadastroTalhao;
begin
  frm := TViewCadastroTalhao.Create(Application);
  try
    frm.Show;
  finally

  end;
end;

procedure TfrmMain.rectBtnConsultaClick(Sender: TObject);
var
  frm: TviewConsultaTalhao;
begin
  frm := TviewConsultaTalhao.Create(Application);
  try
    frm.Show;
  finally

  end;
end;

procedure TfrmMain.rectBtnCadastroMouseEnter(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FFCC8800;
end;

procedure TfrmMain.rectBtnCadastroMouseLeave(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FFDF9D00;
end;

procedure TfrmMain.rectBtnConsultaMouseEnter(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FF2E7D32;
end;

procedure TfrmMain.rectBtnConsultaMouseLeave(Sender: TObject);
begin
  TRectangle(Sender).Fill.Color := $FF388E3C;
end;

end.
