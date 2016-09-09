
  CREATE OR REPLACE PACKAGE "VRS"."PACK_UTIL_STR" 
IS
/**
  Utility functions/procedures for working with text/strings.

  Revised 02/8/2008 by Brad Powell:
    Added startsWith() function.

  Revised 08/15/2006 by Brad Powell:
    Added fieldCriteriaType() function.

  Created 08/10/2004 by Brad Powell
*/


/** 
  Adjust the given field/string value, padding (to the right) or chopping
  as necessary, to fit the field's length.
*/
FUNCTION fitField
(
  i_str IN VARCHAR2,
  i_len IN NUMBER, 
  i_pad IN VARCHAR2 := ' '
)
RETURN VARCHAR2
;


/** 
  Determine the type of criteria search to use for the given string field value.
  To do this, the function will search the field value for indicators like 
  wildcard characters, list delimiters, etc.
  Return an integer representing the enumerated type of criteria.
*/

/* Enumerations for the criteria type: */
criteriaONEVALUE CONSTANT INTEGER := 1;
criteriaALL      CONSTANT INTEGER := 2;
criteriaWILDCARD CONSTANT INTEGER := 3;
criteriaLIST     CONSTANT INTEGER := 4;

FUNCTION fieldCriteriaType
(
  i_fieldVal      IN VARCHAR2,
  i_listDelimeter IN VARCHAR2 := ','
)
RETURN INTEGER
;


/** 
  Determine if the beginning of a string matches the given search/find string.
*/
FUNCTION startsWith
(
  i_str       IN VARCHAR2,
  i_findStr   IN VARCHAR2
)
RETURN BOOLEAN
;


END pack_util_str;

 
/
CREATE OR REPLACE PACKAGE BODY "VRS"."PACK_UTIL_STR" 
IS
/**
  Utility functions/procedures for working with text/strings.

  Revised 02/8/2008 by Brad Powell:
    Added startsWith() function.

  Revised 08/15/2006 by Brad Powell:
    Added fieldCriteriaType() function.

  Created 08/10/2004 by Brad Powell
*/


-------------------------------------------------------------------------------
FUNCTION fitField
(
  i_str IN VARCHAR2,
  i_len IN NUMBER, 
  i_pad IN VARCHAR2 := ' '
)
RETURN VARCHAR2
IS
/** 
  Adjust the given field/string value, padding (to the right) or chopping
  as necessary, to fit the field's length.
*/
BEGIN
  RETURN RPAD(SUBSTR(NVL(i_str, i_pad), 1, i_len), i_len, i_pad);
END fitField;


-------------------------------------------------------------------------------
FUNCTION fieldCriteriaType
(
  i_fieldVal      IN VARCHAR2,
  i_listDelimeter IN VARCHAR2 := ','
)
RETURN INTEGER
IS
  val VARCHAR2(32767) := LOWER(TRIM(i_fieldVal));
BEGIN
  IF (val = '*'  OR  val = '%'  OR  val = '(all)') THEN
    RETURN criteriaALL;
  ELSIF (INSTR(val, i_listDelimeter) > 0) THEN
    RETURN criteriaLIST;
  ELSIF (INSTR(val, '%') > 0  OR  INSTR(val, '_') > 0) THEN
    RETURN criteriaWILDCARD;
  ELSE
    RETURN criteriaONEVALUE;
  END IF;
END fieldCriteriaType;


-------------------------------------------------------------------------------
FUNCTION startsWith
(
  i_str       IN VARCHAR2,
  i_findStr   IN VARCHAR2
)
RETURN BOOLEAN
IS
  findStrLen INTEGER := LENGTH(i_findStr);
BEGIN
  
  IF (LENGTH(i_str) < findStrLen) THEN
    RETURN FALSE;
  END IF;
  
  IF (SUBSTR(i_str, 1, findStrLen) = i_findStr) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;

END startsWith;



END pack_util_str;
