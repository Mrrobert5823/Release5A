
  CREATE OR REPLACE PACKAGE "VRS"."PACK_ENERGY_METRICS" is

  -- Author  : DILLOA
  -- Created : 9/2/2014 8:24:47 AM
  -- Purpose : 

  procedure get_monthly_data
  (
    i_rpt_mo  in number,
    i_rpt_yr  in number,
    i_ytd     in varchar2,
    o_results out sys_refcursor
  );

end PACK_ENERGY_METRICS;
/
CREATE OR REPLACE PACKAGE BODY "VRS"."PACK_ENERGY_METRICS" is

  pLOG_CTX PLOG.LOG_CTX := VRS.PACK_LOAD_PARAMS.pLOG_CTX_Default;

  procedure get_monthly_data
  (
    i_rpt_mo  in number,
    i_rpt_yr  in number,
    i_ytd     in varchar2,
    o_results out sys_refcursor
  ) is
    v_period   varchar2(7) := to_char(i_rpt_yr) || to_char(i_rpt_mo);
    v_start_mo number := case
                           when nvl(i_ytd, 'N') = 'Y' then
                            1
                           else
                            i_rpt_mo
                         end;
  begin
    open o_results for
      select to_number(rpt_mo) as rpt_mo,
             to_number(rpt_yr) as rpt_yr,
             ram.anc_cd || ' | ' || ram.anc_name as resource_advisor_id,
             data_type,
             sum(qty) as qty
      from (
            --Get results for schedule pipelines
            select to_number(report_mo) as rpt_mo,
                    to_number(report_yr) as rpt_yr,
                    substr(trim(from_to), length(trim(from_to)) - 4, 3) as facility_cd,
                    'Barrels' as data_type,
                    bbls_delivered as qty
            from table(vrs.pack_thruput_rpt.TP_YTD_TBL(v_period)) tbl,
                  schedule_pipeline sp
            where substr(trim(from_to), length(trim(from_to)) - 4, 3) =
                  trim(sp.pipeline_facility_cd)
            
            union all
            
            select to_number(tbl.report_month),
                   to_number(tbl.report_year),
                   substr(trim(from_to), length(trim(from_to)) - 4, 3) as facility_cd,
                   'Barrel Miles',
                   tbl.barrelmiles
            from table(vrs.pack_barrelmile_rpt.BM_YTD_TBL(v_period)) tbl,
                 schedule_pipeline sp
            where substr(trim(from_to), length(trim(from_to)) - 4, 3) =
                  trim(sp.pipeline_facility_cd)
            
            union all
            
            select to_number(tbl.report_mo),
                   to_number(tbl.report_year),
                   tbl.facilitycd,
                   'Barrels',
                   tbl.bbls_delivered
            from table(vrs.pack_terminalthruput_rpt.TTP_YTD_TBL(v_period)) tbl,
                 facility_v f
            where tbl.facilitycd = trim(f.facility_cd)
            and trim(upper(tbl.transportation_mode_desc)) <> 'PIPELINE'
            
            union all
            
            --Get results for pipeline systems
            select to_number(report_mo),
                   to_number(report_yr),
                   ps.pipeline_sys_cd,
                   'Barrels',
                   bbls_delivered
            from table(vrs.pack_thruput_rpt.TP_YTD_TBL(v_period)) tbl,
                 pipeline_system ps
            where tbl.pipelinesyscd = trim(ps.pipeline_sys_cd)
            
            union all
            
            select to_number(tbl.report_month),
                   to_number(tbl.report_year),
                   ps.pipeline_sys_cd,
                   'Barrel Miles',
                   tbl.barrelmiles
            from table(vrs.pack_barrelmile_rpt.BM_YTD_TBL(v_period)) tbl,
                 pipeline_system ps
            where substr(tbl.pipelinesys,
                         length(trim(tbl.pipelinesys)) - 3,
                         3) = trim(ps.pipeline_sys_cd)) data,
           vrs.resource_advisor_mapping ram
      where data.facility_cd = ram.facility_cd
      and rpt_yr = i_rpt_yr
      and rpt_mo between v_start_mo and i_rpt_mo
      group by rpt_mo,
               rpt_yr,
               ram.anc_cd || ' | ' || ram.anc_name,
               data_type;
  
  exception
    when others then
      plog.log(pCTX   => pLOG_CTX,
               pLEVEL => VRS.PACK_LOAD_PARAMS.ERR_1i_LEVEL,
               pTEXTE => 'VRS.PACK_ENERGY_METRICS.get_monthly_data - ' ||
                         SQLERRM || CHR(10) || CHR(10) ||
                         DBMS_UTILITY.FORMAT_CALL_STACK || CHR(10) ||
                         dbms_utility.format_error_backtrace);
    
      o_results := null;
  end get_monthly_data;

end PACK_ENERGY_METRICS;