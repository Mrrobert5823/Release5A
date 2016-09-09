
  CREATE OR REPLACE PACKAGE "VRS"."PACK_ECT_MONITOR" 
AS
  -- Author  : TRAC66 / rajus
  -- Created : 05/20/2014
  -- Purpose : Stored procedures - ECT feed alarm for TRAC66

PROCEDURE pcg_ect_feed_alarm;
--This came from feature #1
--This is the first one we are doing




end Pack_ECT)Monitor;
/
CREATE OR REPLACE PACKAGE BODY "VRS"."PACK_ECT_MONITOR" 
  -- Author  : TRAC66 / rajus
  -- Created : 01/23/2014
  -- Purpose : ECT feed Alarm procedures for TRAC66
  -- made an additional change here
IS
pLOG_CTX_Default PLOG.LOG_CTX := PLOG.init ( pLEVEL => plog.LERROR );

------------------------------------------------------------------------------------------------
--  All exception reporting goes through this routine to pass the query generated message upon
--  exception to PLOG, but this routine gives ease of control of the remaining parameters passed.
PROCEDURE log_exception
(
  pText  IN CHAR
)
IS
BEGIN
      plog.log(pCTX => pLOG_CTX_Default, pLEVEL => plog.LERROR,  pTEXTE => pText);
END;

------------------------------------------------------------------------------------------------
PROCEDURE pcg_ect_feed_alarm
IS
          pLOG_CTX_Default PLOG.LOG_CTX := PLOG.init ( pLEVEL => plog.LERR_3 );
          max_vrs_date_time             vrs.ect_ticket.vrs_date_time%TYPE;
          db_instance                   VARCHAR2(20);
          db_host                       VARCHAR2(64);
          pText                         VARCHAR2(2000);
BEGIN

          SELECT MAX(vrs_date_time)
            INTO max_vrs_date_time
            FROM (SELECT vrs_date_time
                    FROM ect_ticket
                  UNION
                  SELECT vrs_date_time
                    FROM pipeline_ticket
                  UNION
                  SELECT vrs_date_time FROM pipeline_ticket_kickout) SAMPLE
           WHERE SAMPLE.Vrs_Date_Time <= SYSDATE;

          IF max_vrs_date_time < SYSDATE - interval '90' minute
          THEN
                    SELECT DISTINCT sys_context('userenv', 'instance_name') AS instance_name,
                                    sys_context('userenv', 'server_host') AS host_name
                      INTO db_instance, db_host
                      FROM dual;

                    pText      := db_host||'-'||db_instance||'-'||'Attention: ECT feed is missing for the last 90 minutes in tables ECT_TICKET, PIPELINE_TICKET and PIPELINE_TICKET_KICKOUT.';
                    plog.log(pCTX => pLOG_CTX_Default, pLEVEL => plog.LERR_3,  pTEXTE => pText);
          END IF;

EXCEPTION
    WHEN OTHERS THEN
                log_exception( pText => 'Function pcg_ect_feed_alarm ERROR - ' || SQLERRM || CHR(10) || CHR(10) ||
               DBMS_UTILITY.FORMAT_CALL_STACK || CHR(10) ||
               dbms_utility.format_error_backtrace
               || CHR(10) || 'CALL ARG''s ->'
               || CHR(10) || '('''
               || CHR(10) || ''')'
               );
END pcg_ect_feed_alarm;

END PACK_ECT_MONITOR;
