unit view.consulta.talhao;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListBox, FMX.Edit,
  FMX.SearchBox,
  models, System.StrUtils, FMX.DialogService;

type
  TviewConsultaTalhao = class(TForm)
    rectHeader: TRectangle;
    btnVoltar: TButton;
    lblTitulo: TLabel;
    btnNovo: TButton;
    rectFiltros: TRectangle;
    edtBusca: TSearchBox;
    cmbGrupo: TComboBox;
    listViewTalhoes: TListView;
    rectVazio: TRectangle;
    lblVazio: TLabel;
    lblVazioDesc: TLabel;
    btnNovoPrimeiro: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnVoltarClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnNovoPrimeiroClick(Sender: TObject);
    procedure listViewTalhoesDeletion(Sender: TObject; AIndex: Integer);
    procedure listViewTalhoesItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure edtBuscaChange(Sender: TObject);
    procedure cmbGrupoChange(Sender: TObject);
  private
    FTalhoes: TTalhaoList;
    FGrupos: TStringList;

    procedure CarregarTalhoes;
    procedure PopularListView(const AFiltroNome, AFiltroGrupo: string);
    procedure CarregarGruposFiltro;
    procedure AbrirNovo;
    procedure AbrirEdicao(ATalhaoId: Integer);
  public
  end;

var
  viewConsultaTalhao: TviewConsultaTalhao;

implementation

{$R *.fmx}

uses
  view.cadastro.talhao.web
  {$IFNDEF MSWINDOWS}
  , view.cadastro.talhao.map
  {$ENDIF}, model.con;

procedure TviewConsultaTalhao.FormCreate(Sender: TObject);
begin
  FTalhoes := TTalhaoList.Create(True);
  FGrupos  := TStringList.Create;
end;

procedure TviewConsultaTalhao.FormDestroy(Sender: TObject);
begin
  FTalhoes.Free;
  FGrupos.Free;
end;

procedure TviewConsultaTalhao.FormShow(Sender: TObject);
begin
  CarregarTalhoes;
  CarregarGruposFiltro;
  PopularListView('', 'Todos');
end;

procedure TviewConsultaTalhao.CarregarTalhoes;
begin
  FTalhoes.Free;
  FTalhoes := dmCon.ListarTalhoes;
end;

procedure TviewConsultaTalhao.PopularListView(const AFiltroNome, AFiltroGrupo: string);
var
  LTalhao: TTalhao;
  LItem: TListViewItem;
  LNomeFiltro, LGrupoFiltro: string;
begin
  listViewTalhoes.Items.Clear;
  LNomeFiltro  := AFiltroNome.ToLower.Trim;
  LGrupoFiltro := AFiltroGrupo;

  for LTalhao in FTalhoes do
  begin
    if (LNomeFiltro <> '') and not LTalhao.Nome.ToLower.Contains(LNomeFiltro) then
      Continue;

    if (LGrupoFiltro <> '') and (LGrupoFiltro <> 'Todos') and(LTalhao.Grupo <> LGrupoFiltro) then
      Continue;

    LItem := listViewTalhoes.Items.Add;
    LItem.Tag    := LTalhao.Id;
    LItem.Text   := LTalhao.Nome;

    LItem.Detail := Format('%.2f km  •  %.2f ha  •  %s',
                     [LTalhao.Perimetro, LTalhao.Area,
                      IfThen(LTalhao.Grupo <> '', LTalhao.Grupo, 'Sem grupo')]);

    LItem.Objects.AccessoryObject.Visible := True;
  end;

  rectVazio.Visible           := listViewTalhoes.Items.Count = 0;
  listViewTalhoes.Visible     := listViewTalhoes.Items.Count > 0;
end;

procedure TviewConsultaTalhao.CarregarGruposFiltro;
var
  S: string;
begin
  FGrupos.Free;
  FGrupos := dmCon.ListarGrupos;
  cmbGrupo.Items.Clear;
  cmbGrupo.Items.Add('Todos');

  for S in FGrupos do
    cmbGrupo.Items.Add(S);

  cmbGrupo.ItemIndex := 0;
end;

procedure TviewConsultaTalhao.AbrirNovo;
begin
  {$IFDEF MSWINDOWS}
  var frm := TViewCadastroTalhao.Create(Application);
  try
    if frm.ShowModal = mrOk then
    begin
      CarregarTalhoes;
      CarregarGruposFiltro;
      PopularListView(edtBusca.Text, cmbGrupo.Selected.Text);
    end;
  finally
    frm.Free;
  end;
  {$ELSE}
  var frm := TViewCadastroTalhao.Create(Application);
  frm.Show;
  {$ENDIF}
end;

procedure TviewConsultaTalhao.AbrirEdicao(ATalhaoId: Integer);
var
  LTalhao: TTalhao;
begin
  LTalhao := dmCon.BuscarTalhaoPorId(ATalhaoId);

  if not Assigned(LTalhao) then
  begin
    TDialogService.ShowMessage('Talhão não encontrado.');
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  var frm := TViewCadastroTalhao.Create(Application);
  try
    frm.CarregarTalhaoExistente(LTalhao);
    if frm.ShowModal = mrOk then
    begin
      CarregarTalhoes;
      CarregarGruposFiltro;
      PopularListView(edtBusca.Text, cmbGrupo.Selected.Text);
    end;
  finally
    frm.Free;
  end;
  {$ELSE}
  var frm := TViewCadastroTalhaoMap.Create(Application);
  frm.CarregarTalhaoExistente(LTalhao);
  frm.Show;
  {$ENDIF}
end;

procedure TviewConsultaTalhao.listViewTalhoesItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  AbrirEdicao(AItem.Tag);
end;

procedure TviewConsultaTalhao.listViewTalhoesDeletion(Sender: TObject; AIndex: Integer);
var
  LItem: TListViewItem;
  LId: Integer;
  LNome: string;
begin
  LItem := listViewTalhoes.Items[AIndex];
  LId   := LItem.Tag;
  LNome := LItem.Text;

  TDialogService.MessageDialog('Excluir "' + LNome + '"?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        dmCon.ExcluirTalhao(LId);
        CarregarTalhoes;
        CarregarGruposFiltro;
        PopularListView(edtBusca.Text, cmbGrupo.Selected.Text);
      end;
    end);
end;

procedure TviewConsultaTalhao.btnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TviewConsultaTalhao.btnNovoClick(Sender: TObject);
begin
  AbrirNovo;
end;

procedure TviewConsultaTalhao.btnNovoPrimeiroClick(Sender: TObject);
begin
  AbrirNovo;
end;

procedure TviewConsultaTalhao.edtBuscaChange(Sender: TObject);
begin
  PopularListView(edtBusca.Text, cmbGrupo.Selected.Text);
end;

procedure TviewConsultaTalhao.cmbGrupoChange(Sender: TObject);
begin
  PopularListView(edtBusca.Text, cmbGrupo.Selected.Text);
end;

end.
