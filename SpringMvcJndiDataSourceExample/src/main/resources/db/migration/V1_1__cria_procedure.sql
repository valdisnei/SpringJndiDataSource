create or replace PROCEDURE TESTE_FLYWAY(
      p_id_empresa            IN       VARCHAR2,
   p_nome_empresa          IN       VARCHAR2,
   p_nr_documento          IN       VARCHAR2,
   p_tp_documento          IN       NUMBER,
   p_dhr_inicio            IN       VARCHAR2,
   p_dhr_fim               IN       VARCHAR2,
   p_date_type             IN       VARCHAR2,
   p_parcel_status         IN       VARCHAR2,
   p_companyidindicator    IN       VARCHAR2,
   p_userloggedcompanyid   IN       VARCHAR2,
   p_recordset             OUT      sys_refcursor
)
AS
   v_sql                          VARCHAR2 (20000) := NULL;
   v_sql2                         VARCHAR2 (20000) := NULL;
   v_query                        VARCHAR2 (30000) := NULL;
   v_is_credito                   VARCHAR2 (100)  := 'NO';
   v_is_remessa_or_retorno        VARCHAR2 (100)  := 'NO';
   v_query_from_credito           VARCHAR2 (1000)  := NULL;
   v_query_select_c_credito       VARCHAR2 (1000)  := NULL;
   v_query_select_c2_credito      VARCHAR2 (1000)  := NULL;
   v_query_select_c_pedido_tipo   VARCHAR2 (1000)  := NULL;

   p_where_nr_documento           VARCHAR2 (1000)  := NULL;
   p_where_nr_documento2          VARCHAR2 (1000)  := NULL;
   p_where_nr_documento3          VARCHAR2 (1000)  := NULL;

   p_where_betwee_data            VARCHAR2 (1000)  := ' and ';

   p_where_betwee_data_select_a   VARCHAR2 (1000)  := NULL;
   p_where_parcel_status          VARCHAR2 (1000)  := NULL;

   p_where_indicador_empresa      VARCHAR2 (1000)  := NULL;

   fromVtransacao_A               varchar2(1000) :=NULL;

   v_columns_ESTORNO              varchar2(2000) :='';

   v_estorno_bloco_D                varchar2(2000) :='';

   v_columns                      varchar2(2000) := '   select  /*+ RULE */ b.x0_0_, b.x1_0_ ,b.x2_0_,b.x3_0_,b.x4_0_,b.x5_0_,b.x6_0_,b.x7_0_,b.x8_0_,b.x9_0_,b.x10_0_,
  b.x11_0_,b.x12_0_,b.x13_0_,b.x14_0_,b.x15_0_,b.x16_0_,
  b.x17_0_,b.x18_0_,b.x19_0_,c.x20_0_,
  b.x21_0_, a.qtde as qtde_debito , c.x22_0_, c.qtde as qtde_credito,
  b.x23_0_, b.x24_0_,
  b.x25_0_, b.x26_0_,
  b.x27_0_, b.x28_0_,
  b.x29_0_, B.X30_0_ as x30_0_,
  b.x31_0_, c.x32_0_,
  c.x33_0_, c.x34_0_,
  C.X35_0_  as x35_0_, c.x36_0_,
  c.x37_0_, c.x38_0_';

   v_range_data                   VARCHAR2 (1000)
      :=    'to_date('''
         || p_dhr_inicio
         || ' 00:00:00'', ''DD/MM/YYYY HH24:MI:SS'') and to_date('''
         || p_dhr_fim
         || ' 23:59:59'', ''DD/MM/YYYY HH24:MI:SS'')';
BEGIN

   IF p_date_type IS NOT NULL
   THEN
      IF p_date_type = 'PAGAMENTO'
      THEN
         -- Parâmetro de INTERVALO DE DATAS
         v_query_select_c_credito := ' transacao  ';

         fromVtransacao_A := ' transacao t';

         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                     ' and (pa.dt_pagamento between ' || v_range_data || ') ';
         ELSE
            p_where_betwee_data := '';
         END IF;

         v_columns_ESTORNO:=', '''' as x39_0_, '''' as x40_0_,'''' as x41_0_, '''' as x42_0_,'''' as x43_0_, '''' as x44_0_,'''' as x45_0_, '''' as x46_0_,'''' as x47_0_,b.x32_0_';

         p_where_betwee_data_select_a := p_where_betwee_data;
      END IF;

      IF p_date_type = 'VENCIMENTO'
      THEN
         -- Parâmetro de INTERVALO DE DATAS
         v_query_select_c_credito := ' transacao t';

         fromVtransacao_A := ' transacao  t';

         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                      '  and (pa.dt_parcela between ' || v_range_data || ') ';
         ELSE
            p_where_betwee_data := '';
         END IF;

         v_columns_ESTORNO:=', '''' as x39_0_, '''' as x40_0_,'''' as x41_0_, '''' as x42_0_,'''' as x43_0_, '''' as x44_0_,'''' as x45_0_, '''' as x46_0_,'''' as x47_0_,b.x32_0_';

         p_where_betwee_data_select_a := p_where_betwee_data;
      END IF;

      IF p_date_type = 'REMESSA DEBITO'
      THEN
         v_is_remessa_or_retorno := 'OK';
         -- Parâmetro de INTERVALO DE DATAS
         v_query_select_c_credito := ' transacao  ';

          fromVtransacao_A := ' v_transacao t';


         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                   '  and (T.DHR_ENVIO_LOT between ' || v_range_data || ')  ';
            p_where_betwee_data :=
                     p_where_betwee_data || ' and pt.id_pedido_trans_tipo=3 ';
         ELSE
            p_where_betwee_data := '';
         END IF;

         p_where_betwee_data_select_a := p_where_betwee_data;

         v_estorno_bloco_D:=', (select d1.*, d2.qtde from
                (SELECT pa.dt_parcela,  T.CTL_TRANA_BCO,pt.nsu, t.ctl_trana_ori,
              t.vlr_tarif_opr  as tarifa_pamcard_Estorno,
              t.dhr_envio_lot as dt_envio_estorno,
                t.des_lote_trn as lote_estorno, t.dhr_retor_lot as dta_retorno_estorno,
                t.nom_retor_lot as lote_retorno_estorno, t.vlr_total_trc as vlr_estorno,
                t.sig_mensg_tip as mensagem_estorno, t.des_situa_tip as situa_estorno ,
                pa.dt_pagamento ,t.ctl_opera_tip , pt.id_parcela
              from v_transacao  t, parcela pa, pedido_transacao pt, VIAGEM V
              where V.ID_VIAGEM=PA.ID_VIAGEM AND  T.CTL_OPERA_TIP=2 AND
               T.COD_CONTR_CLI=PT.NSU AND  PT.ID_PARCELA=PA.ID_PARCELA AND  PT.ID_PEDIDO_TRANS_TIPO=5 and
               t.ctl_trana_bco in (select max(x.ctl_trana_bco) from transacao  x where x.ctl_trana_ori=t.ctl_trana_ori)) d1,
               (select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=5  group by id_parcela) d2
              where d2.id_parcela=d1.id_parcela  )  d ';

        v_columns_ESTORNO:=',d.tarifa_pamcard_Estorno, d.dt_envio_estorno,d.lote_estorno, d.dta_retorno_estorno,d.lote_retorno_estorno, d.vlr_estorno,d.mensagem_estorno, d.situa_estorno, d.qtde as qtde_estorno,b.x32_0_';



      END IF;

      --REMESSA INICIO DO FILTRO  ->  VALIDAR
      IF p_date_type = 'REMESSA CREDITO'
      THEN


      v_columns :='select  /*+ RULE */  b.x0_0_, b.x1_0_ ,b.x2_0_,b.x3_0_,b.x4_0_,b.x5_0_,b.x6_0_,b.x7_0_,b.x8_0_,b.x9_0_,b.x10_0_,
              b.x11_0_,b.x12_0_,b.x13_0_,b.x14_0_,b.x15_0_,b.x16_0_,
              b.x17_0_,b.x18_0_,k.cod_contr_cli as x19_0_,c.x20_0_,
                k.ctl_trana_bco as x21_0_, a.qtde as qtde_debito , c.x22_0_, c.qtde as qtde_credito,
                k.dhr_envio_lot as x23_0_, k.des_lote_trn as x24_0_,
                k.dhr_retor_lot as x25_0_, k.nom_retor_lot as x26_0_,
                b.x27_0_, b.x28_0_,
                b.x29_0_, B.X30_0_ as x30_0_,
                b.x31_0_, c.x32_0_,
                c.x33_0_, c.x34_0_,
                C.X35_0_  as x35_0_, c.x36_0_,
                c.x37_0_, c.x38_0_  ,
                d.tarifa_pamcard_Estorno,
                d.dt_envio_estorno,
                d.lote_estorno, d.dta_retorno_estorno,
                d.lote_retorno_estorno, d.vlr_estorno,
                d.mensagem_estorno, d.situa_estorno, d.qtde as qtde_estorno,b.x32_0_';


        v_estorno_bloco_D:=', (select d1.*, d2.qtde from
                (SELECT pa.dt_parcela,  T.CTL_TRANA_BCO,pt.nsu, t.ctl_trana_ori,
              t.vlr_tarif_opr  as tarifa_pamcard_Estorno,
              t.dhr_envio_lot as dt_envio_estorno,
                t.des_lote_trn as lote_estorno, t.dhr_retor_lot as dta_retorno_estorno,
                t.nom_retor_lot as lote_retorno_estorno, t.vlr_total_trc as vlr_estorno,
                t.sig_mensg_tip as mensagem_estorno, t.des_situa_tip as situa_estorno ,
                pa.dt_pagamento ,t.ctl_opera_tip , pt.id_parcela
              from v_transacao  t, parcela pa, pedido_transacao pt, VIAGEM V
              where V.ID_VIAGEM=PA.ID_VIAGEM AND  T.CTL_OPERA_TIP=2 AND
               T.COD_CONTR_CLI=PT.NSU AND  PT.ID_PARCELA=PA.ID_PARCELA AND  PT.ID_PEDIDO_TRANS_TIPO=5 and
               t.ctl_trana_bco in (select max(x.ctl_trana_bco) from transacao  x where x.ctl_trana_ori=t.ctl_trana_ori)) d1,
               (select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=5  group by id_parcela) d2
              where d2.id_parcela=d1.id_parcela  )  d, v_transacao k ';


         v_is_remessa_or_retorno := 'OK';
         v_is_credito := 'OK';
         v_query_select_c_credito := ' v_transacao  ';

         fromVtransacao_A := ' transacao t';

         -- Parâmetro de INTERVALO DE DATAS
         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                   '  and (T.DHR_ENVIO_LOT between ' || v_range_data || ')  ';
            p_where_betwee_data :=
               p_where_betwee_data || ' and pt.id_pedido_trans_tipo=4';
         ELSE
            p_where_betwee_data := '';
         END IF;
      END IF;

      --REMESSA FINAL DO FILTRO
      --RETORNO INICIO DO FILTRO -> VALIDAR
      IF p_date_type = 'RETORNO CREDITO'
      THEN

      fromVtransacao_A := ' transacao t';


      v_columns :='select  /*+ RULE */  b.x0_0_, b.x1_0_ ,b.x2_0_,b.x3_0_,b.x4_0_,b.x5_0_,b.x6_0_,b.x7_0_,b.x8_0_,b.x9_0_,b.x10_0_,
      b.x11_0_,b.x12_0_,b.x13_0_,b.x14_0_,b.x15_0_,b.x16_0_,
      b.x17_0_,b.x18_0_,k.cod_contr_cli as x19_0_,c.x20_0_,
      b.x21_0_, a.qtde as qtde_debito , c.x22_0_, c.qtde as qtde_credito,
      k.dhr_envio_lot as x23_0_, k.des_lote_trn as x24_0_,
      k.dhr_retor_lot as x25_0_, k.nom_retor_lot as x26_0_,
      b.x27_0_, b.x28_0_,
      b.x29_0_, substr(b.x26_0_,1,28)  as x30_0_,
      b.x31_0_, c.x32_0_,
      c.x33_0_, c.x34_0_,
      C.X35_0_  as x35_0_, c.x36_0_,
      c.x37_0_, c.x38_0_  ,
      d.tarifa_pamcard_Estorno,
      d.dt_envio_estorno,
      d.lote_estorno, d.dta_retorno_estorno,
      d.lote_retorno_estorno, d.vlr_estorno,
      d.mensagem_estorno, d.situa_estorno, d.qtde as qtde_estorno,b.x32_0_';


      v_estorno_bloco_D:=', (select d1.*, d2.qtde from
      (SELECT pa.dt_parcela,  T.CTL_TRANA_BCO,pt.nsu, t.ctl_trana_ori,
      t.vlr_tarif_opr  as tarifa_pamcard_Estorno,
      t.dhr_envio_lot as dt_envio_estorno,
        t.des_lote_trn as lote_estorno, t.dhr_retor_lot as dta_retorno_estorno,
        t.nom_retor_lot as lote_retorno_estorno, t.vlr_total_trc as vlr_estorno,
        t.sig_mensg_tip as mensagem_estorno, t.des_situa_tip as situa_estorno ,
        pa.dt_pagamento ,t.ctl_opera_tip , pt.id_parcela
      from v_transacao  t, parcela pa, pedido_transacao pt, VIAGEM V
      where V.ID_VIAGEM=PA.ID_VIAGEM AND  T.CTL_OPERA_TIP=2 AND
       T.COD_CONTR_CLI=PT.NSU AND  PT.ID_PARCELA=PA.ID_PARCELA AND  PT.ID_PEDIDO_TRANS_TIPO=5 and
       t.ctl_trana_bco in (select max(x.ctl_trana_bco) from transacao  x where x.ctl_trana_ori=t.ctl_trana_ori)) d1,
       (select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=5  group by id_parcela) d2
      where d2.id_parcela=d1.id_parcela  )  d, v_transacao k  ';


         v_is_remessa_or_retorno := 'OK';
         v_is_credito := 'OK';
         v_query_select_c_credito := ' transacao  ';

         -- Parâmetro de INTERVALO DE DATAS
         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                   '  and (t.dhr_retor_lot between ' || v_range_data || ')  ';
            p_where_betwee_data :=
               p_where_betwee_data
               || ' and pt.id_pedido_trans_tipo = 4 ';
         ELSE
            p_where_betwee_data := '';
         END IF;
      END IF;

      --RETORNO FINAL DO FILTRO
      IF p_date_type = 'RETORNO DEBITO'
      THEN

          v_estorno_bloco_D:=', (select d1.*, d2.qtde from
(SELECT pa.dt_parcela,  T.CTL_TRANA_BCO,pt.nsu, t.ctl_trana_ori,
t.vlr_tarif_opr  as tarifa_pamcard_Estorno,
t.dhr_envio_lot as dt_envio_estorno,
  t.des_lote_trn as lote_estorno, t.dhr_retor_lot as dta_retorno_estorno,
  t.nom_retor_lot as lote_retorno_estorno, t.vlr_total_trc as vlr_estorno,
  t.sig_mensg_tip as mensagem_estorno, t.des_situa_tip as situa_estorno ,
  pa.dt_pagamento ,t.ctl_opera_tip , pt.id_parcela
from v_transacao  t, parcela pa, pedido_transacao pt, VIAGEM V
where V.ID_VIAGEM=PA.ID_VIAGEM AND  T.CTL_OPERA_TIP=2 AND
 T.COD_CONTR_CLI=PT.NSU AND  PT.ID_PARCELA=PA.ID_PARCELA AND  PT.ID_PEDIDO_TRANS_TIPO=5 and
 t.ctl_trana_bco in (select max(x.ctl_trana_bco) from transacao  x where x.ctl_trana_ori=t.ctl_trana_ori)) d1,
 (select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=5  group by id_parcela) d2
where d2.id_parcela=d1.id_parcela  )  d ';

         v_columns_ESTORNO:=',
            d.tarifa_pamcard_Estorno,
            d.dt_envio_estorno,
            d.lote_estorno, d.dta_retorno_estorno,
            d.lote_retorno_estorno, d.vlr_estorno,
            d.mensagem_estorno, d.situa_estorno, d.qtde as qtde_estorno,b.x32_0_';

         v_is_remessa_or_retorno := 'OK';
         v_query_select_c_credito := ' transacao  ';

          fromVtransacao_A := ' v_transacao t ';



         -- Parâmetro de INTERVALO DE DATAS
         IF p_dhr_inicio IS NOT NULL AND p_dhr_fim IS NOT NULL
         THEN
            p_where_betwee_data :=
                  '  and ( t.dhr_retor_lot between ' || v_range_data || ')  ';
            p_where_betwee_data :=
                    p_where_betwee_data || ' and pt.id_pedido_trans_tipo=3  ';
         ELSE
            p_where_betwee_data := '';
         END IF;

         p_where_betwee_data_select_a := p_where_betwee_data;
      END IF;
   --RETORNO FINAL DO FILTRO
   END IF;

   IF p_parcel_status IS NOT NULL
   THEN
      IF    (p_date_type IS NOT NULL)
         OR (p_where_betwee_data_select_a = p_where_betwee_data)
      THEN
         p_where_parcel_status :=
                 ' and (pa.id_parcela_status in(' || p_parcel_status || ')) ';
      ELSE
         p_where_parcel_status :=
                     ' (pa.id_parcela_status in(' || p_parcel_status || ')) ';
      END IF;
   END IF;

   IF p_nr_documento IS NOT NULL
   THEN
      IF (p_parcel_status IS NOT NULL) OR (p_date_type IS NOT NULL)
      THEN
         p_where_nr_documento := ' and ';
         p_where_nr_documento2 := ' and ';
         p_where_nr_documento3 := ' and ';
      END IF;

      p_where_nr_documento :=
            p_where_nr_documento
         || ' DE.NR_DOCUMENTO ='''
         || p_nr_documento
         || ''' AND
                                DE.ID_EMPRESA =V.ID_EMPRESA AND
                               (V.ID_EMPRESA=E.ID_EMPRESA OR V.ID_EMPRESA=E.ID_EMPRESA_PAI)';
      p_where_nr_documento2 :=
            p_where_nr_documento2
         || ' DE.NR_DOCUMENTO ='''
         || p_nr_documento
         || ''' AND  DE.ID_EMPRESA =V.ID_EMPRESA ';
      p_where_nr_documento3 :=
            p_where_nr_documento3
         || ' (DE.NR_DOCUMENTO ='''
         || p_nr_documento
         || ''' OR Dc.Nr_Documento='''
         || p_nr_documento
         || ''') AND
                                DE.ID_EMPRESA =V.ID_EMPRESA AND
                                (V.Id_Empresa=E.Id_Empresa_Pai Or
                                 v.id_empresa=e.id_empresa) ';
   ELSE
      p_where_nr_documento := '';
      p_where_nr_documento2 := '';
      p_where_nr_documento3 := ' and DE.ID_EMPRESA =V.ID_EMPRESA AND
                                (V.Id_Empresa=E.Id_Empresa_Pai Or
                                 v.id_empresa=e.id_empresa) ';
   END IF;

   IF v_is_credito = 'OK'
   THEN
      v_query_from_credito :=
            ' from '
         || v_query_select_c_credito
         || 't, parcela pa, pedido_transacao pt, viagem v, DOCUMENTO_EMPRESA DE, EMPRESA E ';
      v_query_select_c2_credito :=
              ' where a.ctl_trana_bco=b.ctl_trana_ori and b.x21_0_=c.x22_0_ and a.ctL_TRANA_BCO = d.ctl_trana_ori(+) and a.ctl_trana_bco=k.ctl_trana_bco ';
      v_query_select_c_pedido_tipo := ' PT.ID_PEDIDO_TRANS_TIPO =4 ';
   ELSE
      v_query_from_credito :=
            ' from '
         || v_query_select_c_credito
         || 't, parcela pa, pedido_transacao pt, viagem v, DOCUMENTO_EMPRESA DE, EMPRESA E ';

       if (p_date_type='RETORNO DEBITO' or p_date_type='REMESSA DEBITO' )
       then
            v_query_select_c2_credito :=
              ' where a.ctl_trana_bco=b.x21_0_  and b.x21_0_=C.CTL_TRANA_ORI(+) and b.x21_0_=d.CTL_TRANA_ORI(+)';
       else
            v_query_select_c2_credito :=
              ' where a.ctl_trana_bco=b.x21_0_  and b.x21_0_=C.CTL_TRANA_ORI(+) ';

       end if;


      v_query_select_c_pedido_tipo := ' PT.ID_PEDIDO_TRANS_TIPO=4   ';
   END IF;

   v_sql :=

  v_columns || v_columns_ESTORNO ||'
  from
  ( select a1.* , a2.qtde from
( select max(t.ctl_trana_bco) as ctl_trana_bco, pa.id_parcela from '

|| fromVtransacao_A ||

', parcela pa, pedido_transacao pt, viagem v '
      || ' where  t.cod_contr_cli=pt.nsu
and pt.id_parcela=pa.id_parcela
and pa.id_viagem=v.id_viagem
AND pa.ctl_meio_pag=2
and t.ctl_opera_tip=1  '
      || p_where_betwee_data_select_a
      || '
'
      || p_where_parcel_status
      || '
group by pa.id_parcela, t.ctl_opera_tip) a1 ,
(select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=3  group by id_parcela) a2
where a2.id_parcela=a1.id_parcela  ) a ,

(select '''' as x2_0_ , '''' as x3_0_ ,de.nr_documento as x0_0_, e.nome as x1_0_,
pt.NR_BANCO_EMP as x4_0_,pt.AGENCIA_EMP as x5_0_,pt.nr_conta_emp as x6_0_,
pa.dt_parcela as x7_0_, pa.id_viagem as x8_0_,pa.nr_parcela as x9_0_,pa.id_parcela as x10_0_,
sp.ds_parcela_status as x11_0_, pa.valor as x12_0_,
pa.vl_transacao_taxa as x13_0_,pa.vlr_custo_pag as x14_0_,dp.nr_documento as x15_0_,t.num_banco_des as x16_0_,
t.num_agenc_des as x17_0_, t.num_conta_des as x18_0_,pt.NSU as x19_0_,0 as x20_0_,e.id_empresa,v.id_viagem,v.DT_CADASTRO_VIAGEM,
pa.ID_PARCELA_STATUS,v.dt_partida,t.dhr_retor_trc,
t.ctl_trana_bco as x21_0_, pt.NSU as x22_0_,
t.dhr_envio_lot as x23_0_, t.des_lote_trn as x24_0_,
t.dhr_retor_lot as x25_0_, t.nom_retor_lot as x26_0_,
t.vlr_total_trc as x27_0_, t.vlr_tarif_opr as x28_0_,
t.vlr_custo_opr as x29_0_, t.sig_mensg_tip as x30_0_,
t.des_situa_tip as x31_0_, t.TIP_TRANF as x32_0_,
0 as x33_0_, 0 as x34_0_,
0 as x35_0_, 0 as x36_0_,
0 as x37_0_, 0 as x38_0_,
T.CTL_TRANA_ORI, PT.DT_PEDIDO_transacao,pt.id_pedido_trans_tipo, t.dhr_envio_lot
from empresa e, documento_empresa de, v_transacao  t, parcela pa, viagem_favorecido vf, viagem v,
documento_portador dp,  pedido_transacao pt, parcela_status sp
where v.id_empresa=e.id_empresa and e.id_empresa=de.id_empresa and E.ID_INDICADOR=''C'' and
de.id_documento_tipo=1 and v.id_viagem=pa.id_viagem and pa.id_parcela=pt.id_parcela and
pa.ctl_meio_pag=2 and pt.nsu=t.cod_contr_cli and pa.id_viagem=vf.id_viagem and
pa.ctl_tipo_fav=vf.ctl_tipo_fav and vf.id_portador=dp.id_portador and dp.id_documento_tipo in (1,2) and
pa.id_parcela_status=sp.id_parcela_status
'
      || p_where_betwee_data
      || '
'
      || p_where_parcel_status
      || '
'
      || p_where_nr_documento2
      || '
union all
select de.nr_documento as x2_0_, e.nome as x3_0_,dc.nr_documento as x0_0_, ec.nome as x1_0_,
pt.NR_BANCO_EMP as x4_0_,pt.AGENCIA_EMP as x5_0_,pt.nr_conta_emp as x6_0_,
pa.dt_parcela as x7_0_, pa.id_viagem as x8_0_,pa.nr_parcela as x9_0_,pa.id_parcela as x10_0_,
sp.ds_parcela_status as x11_0_, pa.valor as x12_0_,
pa.vl_transacao_taxa as x13_0_,pa.vlr_custo_pag as x14_0_,dp.nr_documento as x15_0_,t.num_banco_des as x16_0_,
t.num_agenc_des as x17_0_, t.num_conta_des as x18_0_,0 as x19_0_,0 as x20_0_,e.id_empresa,v.id_viagem,v.DT_CADASTRO_VIAGEM,
pa.ID_PARCELA_STATUS,v.dt_partida,t.dhr_retor_trc,t.ctl_trana_bco as x21_0_, pt.NSU as x22_0_,
t.dhr_envio_lot as x23_0_, t.des_lote_trn as x24_0_,
t.dhr_retor_lot as x25_0_, t.nom_retor_lot as x26_0_,
t.vlr_total_trc as x27_0_, t.vlr_tarif_opr as x28_0_,
t.vlr_custo_opr as x29_0_, t.sig_mensg_tip as x30_0_,
t.des_situa_tip as x31_0_, t.TIP_TRANF as x32_0_,
0 as x33_0_, 0 as x34_0_,
0 as x35_0_, 0 as x36_0_,
0 as x37_0_, 0 as x38_0_,
t.ctL_TRANA_ORI, PT.DT_PEDIDO_transacao,pt.id_pedido_trans_tipo, t.dhr_envio_lot
from empresa e, documento_empresa de, v_transacao  t, parcela pa, viagem_favorecido vf, viagem v,
documento_portador dp, pedido_transacao pt,
empresa ec, documento_empresa dc,
parcela_status sp
where v.id_empresa=e.id_empresa and e.id_indicador=''E'' and e.id_empresa_pai=ec.id_empresa and ec.id_empresa=dc.id_empresa and
dc.id_documento_tipo=1 and e.id_empresa=de.id_empresa and v.id_viagem=pa.id_viagem and
pa.id_parcela=pt.id_parcela and pa.ctl_meio_pag=2 and pt.nsu=t.cod_contr_cli and pa.id_viagem=vf.id_viagem and
pa.ctl_tipo_fav=vf.ctl_tipo_fav and vf.id_portador=dp.id_portador and dp.id_documento_tipo in (1,2) and
 pa.id_parcela_status=sp.id_parcela_status
'
      || p_where_betwee_data
      || '
'
      || p_where_parcel_status
      || '
'
      || p_where_nr_documento3||
      '
) b ,
(select c1.*, c2.qtde from
(SELECT pa.dt_parcela,
t.vlr_tarif_opr  as tarifa_pamcard_CRED,  t.vlr_custo_opr  as tarifa_banco_CRED,
T.NUM_BANCO_DES, T.NUM_AGENC_DES, T.NUM_CONTA_DES,
t.dhr_cadas_trc as data_CREDITO, t.dhr_retor_trc , T.CTL_TRANA_ORI, pt.nsu as x20_0_,
  0 as x21_0_, t.ctl_trana_bco as x22_0_,
  0 as x23_0_, 0 as x24_0_,
  0 as x25_0_, 0 as x26_0_,
  0 as x27_0_, 0 as x28_0_,
  0 as x29_0_, 0 as x30_0_,
  0 as x31_0_, t.dhr_envio_lot as x32_0_,
  t.des_lote_trn as x33_0_, t.dhr_retor_lot as x34_0_,
  t.nom_retor_lot as x35_0_, t.vlr_total_trc as x36_0_,
  t.sig_mensg_tip as x37_0_, t.des_situa_tip as x38_0_ ,pa.dt_pagamento,t.ctl_opera_tip, pt.id_parcela,t.cod_contr_cli
from v_transacao  t, parcela pa, pedido_transacao pt, VIAGEM V
where V.ID_VIAGEM=PA.ID_VIAGEM AND  T.CTL_OPERA_TIP=2 AND
 T.COD_CONTR_CLI=PT.NSU AND  PT.ID_PARCELA=PA.ID_PARCELA AND '
      || v_query_select_c_pedido_tipo
      || 
' ) c1,
(select id_parcela, count(*) as qtde from pedido_transacao where id_pedido_trans_tipo=4  group by id_parcela) c2,
(select t3.ctl_trana_ori  from V_transacao t3 
where t3.nom_retor_lot in (select max(x.nom_retor_lot) from v_transacao   x where x.ctl_trana_ori=t3.ctl_trana_ori)) c3
where c2.id_parcela=c1.id_parcela and c1.ctl_trana_ori=c3.ctl_trana_ori(+) )  C '
  || v_estorno_bloco_D

  || v_query_select_c2_credito;


   v_sql2 :=
         'UNION ALL
         select  b.x0_0_, b.x1_0_ ,b.x2_0_,b.x3_0_,b.x4_0_,b.x5_0_,b.x6_0_,b.x7_0_,b.x8_0_,b.x9_0_,b.x10_0_,
b.x11_0_,b.x12_0_,b.x13_0_,b.x14_0_,b.x15_0_,b.x16_0_,
b.x17_0_,b.x18_0_,max(b.x19_0_), 0 ,
  b.x21_0_, 0 ,0,0,  b.x23_0_, b.x24_0_,
  b.x25_0_, b.x26_0_,  b.x27_0_, b.x28_0_,
  b.x29_0_, b.x30_0_,  b.x31_0_, null ,
  '''',null,
  ''''  , 0 ,
  '''', '''',
  '''' as x39_0_, '''' as x40_0_,'''' as x41_0_, '''' as x42_0_,'''' as x43_0_, '''' as x44_0_,'''' as x45_0_, '''' as x46_0_,'''' as x47_0_,0 as x32_0_
  from (select '''' as x0_0_ , '''' as x1_0_ ,de.nr_documento as x2_0_, e.nome as x3_0_,
pt.NR_BANCO_EMP as x4_0_,pt.AGENCIA_EMP as x5_0_,pt.nr_conta_emp as x6_0_,
pa.dt_parcela as x7_0_, pa.id_viagem as x8_0_,pa.nr_parcela as x9_0_,pa.id_parcela as x10_0_,
sp.ds_parcela_status as x11_0_, pa.valor as x12_0_,
pa.vl_transacao_taxa as x13_0_,pa.vlr_custo_pag as x14_0_,dp.nr_documento as x15_0_, 000 as x16_0_,
'''' as x17_0_, '''' as x18_0_,pt.NSU as x19_0_,0 as x20_0_,e.id_empresa,v.id_viagem,v.DT_CADASTRO_VIAGEM,
pa.ID_PARCELA_STATUS,v.dt_partida, '''' ,
0 as x21_0_, 0 as x22_0_,0,0,
null  as x23_0_, '''' x24_0_,
null  as x25_0_, '''' as x26_0_,
0 as x27_0_, 0 as x28_0_,
0 as x29_0_, '''' as x30_0_,
'''' as x31_0_, 0 as x32_0_,
0 as x33_0_, 0 as x34_0_,
'''' as x35_0_, 0 as x36_0_,
''''  as x37_0_, 0 as x38_0_,
0, PT.DT_PEDIDO_transacao,pt.id_pedido_trans_tipo, ''''
from empresa e, documento_empresa de,parcela pa, viagem_favorecido vf, viagem v,
documento_portador dp,  pedido_transacao pt, parcela_status sp
where v.id_empresa=e.id_empresa and e.id_empresa=de.id_empresa and E.ID_INDICADOR=''C'' and
de.id_documento_tipo=1 and v.id_viagem=pa.id_viagem and pa.id_parcela=pt.id_parcela and
pa.ctl_meio_pag=2 and  pa.id_viagem=vf.id_viagem and
pa.ctl_tipo_fav=vf.ctl_tipo_fav and vf.id_portador=dp.id_portador and dp.id_documento_tipo in (1,2) and
pa.id_parcela_status=sp.id_parcela_status
'
      || p_where_betwee_data
      || '
'
      || p_where_parcel_status
      || '
'
      || p_where_nr_documento
      || '
AND  DE.ID_EMPRESA =V.ID_EMPRESA  AND DE.ID_DOCUMENTO_TIPO=1
and not exists (select t.cod_contr_cli from transacao  t where t.cod_contr_cli=pt.nsu)
and pt.id_pedido_trans_tipo=3
union all
select de.nr_documento as x0_0_, e.nome as x1_0_,dc.nr_documento as x2_0_, ec.nome as x3_0_,
pt.NR_BANCO_EMP as x4_0_,pt.AGENCIA_EMP as x5_0_,pt.nr_conta_emp as x6_0_,
pa.dt_parcela as x7_0_, pa.id_viagem as x8_0_,pa.nr_parcela as x9_0_,pa.id_parcela as x10_0_,
sp.ds_parcela_status as x11_0_, pa.valor as x12_0_,
pa.vl_transacao_taxa as x13_0_,pa.vlr_custo_pag as x14_0_,dp.nr_documento as x15_0_, 000 as x16_0_,
'''' as x17_0_, '''' as x18_0_,pt.NSU as x19_0_,0 as x20_0_,e.id_empresa,v.id_viagem,v.DT_CADASTRO_VIAGEM,
pa.ID_PARCELA_STATUS,v.dt_partida, '''' ,
0 as x21_0_, 0 as x22_0_,0,0,null  as x23_0_, ''''  x24_0_,
null  as x25_0_, ''''  as x26_0_,0 as x27_0_, 0 as x28_0_,
0 as x29_0_, ''''  as x30_0_,'''' as x31_0_, 0 as x32_0_,
0 as x33_0_, 0 as x34_0_,''''  as x35_0_, 0 as x36_0_,
'''' as x37_0_, 0 as x38_0_,
0, PT.DT_PEDIDO_transacao,pt.id_pedido_trans_tipo, ''''
from empresa e, documento_empresa de, parcela pa, viagem_favorecido vf, viagem v,
documento_portador dp, pedido_transacao pt,
empresa ec, documento_empresa dc,
parcela_status sp
where v.id_empresa=e.id_empresa and e.id_indicador=''E'' and e.id_empresa_pai=ec.id_empresa and ec.id_empresa=dc.id_empresa and
dc.id_documento_tipo=1 and e.id_empresa=de.id_empresa and de.id_documento_tipo=1 and v.id_viagem=pa.id_viagem and
pa.id_parcela=pt.id_parcela and pa.ctl_meio_pag=2 and  pa.id_viagem=vf.id_viagem and
pa.ctl_tipo_fav=vf.ctl_tipo_fav and vf.id_portador=dp.id_portador and dp.id_documento_tipo in (1,2) and
pa.id_parcela_status=sp.id_parcela_status
'
      || p_where_betwee_data
      || '
'
      || p_where_parcel_status
      || '
'
      || p_where_nr_documento3
      || '
and not exists (select t.cod_contr_cli from transacao  t where t.cod_contr_cli=pt.nsu)
and pt.id_pedido_trans_tipo=3
union all
select de.nr_documento as x0_0_, e.nome as x1_0_,dc.nr_documento as x2_0_, ec.nome as x3_0_,
pt.NR_BANCO_EMP as x4_0_,pt.AGENCIA_EMP as x5_0_,pt.nr_conta_emp as x6_0_,
pa.dt_parcela as x7_0_, pa.id_viagem as x8_0_,pa.nr_parcela as x9_0_,pa.id_parcela as x10_0_,
sp.ds_parcela_status as x11_0_, pa.valor as x12_0_,
pa.vl_transacao_taxa as x13_0_,pa.vlr_custo_pag as x14_0_,dp.nr_documento as x15_0_, 000 as x16_0_,
'''' as x17_0_, '''' as x18_0_,pt.NSU as x19_0_,0 as x20_0_,e.id_empresa,v.id_viagem,v.DT_CADASTRO_VIAGEM,
pa.ID_PARCELA_STATUS,v.dt_partida, '''' ,
0 as x21_0_, 0 as x22_0_,0,0,
null   as x23_0_, ''''  x24_0_,
null  as x25_0_, ''''  as x26_0_,
0 as x27_0_, 0 as x28_0_,
0 as x29_0_, '''' as x30_0_,
'''' as x31_0_, 0 as x32_0_,
0 as x33_0_, 0 as x34_0_,
'''' as x35_0_, 0 as x36_0_,
'''' as x37_0_, 0 as x38_0_,
0, PT.DT_PEDIDO_transacao,pt.id_pedido_trans_tipo, ''''
from empresa e, documento_empresa de, parcela pa, viagem_favorecido vf, viagem v,
documento_portador dp, pedido_transacao pt,
empresa ec, documento_empresa dc,
parcela_status sp
where v.id_empresa=e.id_empresa and e.id_indicador=''E'' and e.id_empresa_pai=ec.id_empresa and ec.id_empresa=dc.id_empresa and
dc.id_documento_tipo=1 and e.id_empresa=de.id_empresa and de.id_documento_tipo<>1 and v.id_viagem=pa.id_viagem and
pa.id_parcela=pt.id_parcela and pa.ctl_meio_pag=2 and  pa.id_viagem=vf.id_viagem and
pa.ctl_tipo_fav=vf.ctl_tipo_fav and vf.id_portador=dp.id_portador and dp.id_documento_tipo in (1,2) and
pa.id_parcela_status=sp.id_parcela_status
'
      || p_where_betwee_data
      || '
'
      || p_where_parcel_status
      || '
'
      || p_where_nr_documento3
      || '
AND not exists (select x.id_empresa from documento_empresa x where x.id_empresa=e.id_empresa and x.id_documento_tipo=1)
and not exists (select t.cod_contr_cli from transacao  t where t.cod_contr_cli=pt.nsu)
and pt.id_pedido_trans_tipo=3
) B
group by
b.x0_0_, b.x1_0_ ,b.x2_0_,b.x3_0_,b.x4_0_,b.x5_0_,b.x6_0_,b.x7_0_,b.x8_0_,b.x9_0_,b.x10_0_,
b.x11_0_,b.x12_0_,b.x13_0_,b.x14_0_,b.x15_0_,b.x16_0_,
b.x17_0_,b.x18_0_,b.x21_0_,b.x23_0_, b.x24_0_,b.x25_0_, b.x26_0_,
  b.x27_0_, b.x28_0_,  b.x29_0_, b.x30_0_,  b.x31_0_';

   IF v_is_remessa_or_retorno = 'OK'
   THEN
      v_query := v_sql;
   ELSE
      v_query := v_sql || v_sql2;
   END IF;
   OPEN p_recordset FOR v_query;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('Código do Erro: ' || SQLCODE || ' - ' || SQLERRM);
END;
/