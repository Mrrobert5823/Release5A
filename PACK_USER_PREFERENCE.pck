
  CREATE OR REPLACE PACKAGE "VRS"."PACK_USER_PREFERENCE" 
IS
/**
  Various procedures/functions for dealing with user preferences.


  Created 12/7/2007 by Brad Powell.
*/


/** 
  Retrieve all preferences (as key/value pairs) for the given user.
  Return the results in a ref cursor.

  Called from: CMS2 (a.k.a. iPipe) web services.
*/
PROCEDURE get_preferences
(
  i_userId           IN  VARCHAR2,
  o_userPreferences  OUT SYS_REFCURSOR
);


/** 
  Retrieve preference value for the given user and preference key.
  Return the results in a ref cursor.

  Called from: CMS2 (a.k.a. iPipe) web services.
*/
FUNCTION get_preference
(
  i_userId    IN  VARCHAR2,
  i_prefKey   IN  VARCHAR2
)
RETURN VARCHAR2;


/** 
  Set (insert or update) the preference value for the given user and preference key.
  Return the results in a ref cursor.

  The following application exceptions may be raised:
    -20200 : Unable to insert new preference into user_preference table.
    -20201 : Unable to update preference value in user_preference table.

  Called from: CMS2 (a.k.a. iPipe) web services.
*/
PROCEDURE set_preference
(
  i_userId     IN  VARCHAR2,
  i_prefKey    IN  VARCHAR2,
  i_prefValue  IN  VARCHAR2
);



END pack_User_Preference;

 
/
CREATE OR REPLACE PACKAGE BODY "VRS"."PACK_USER_PREFERENCE" 
IS
/**
  Created 12/7/2007 by Brad Powell.
*/


-------------------------------------------------------------------------------
PROCEDURE get_preferences
(
  i_userId           IN  VARCHAR2,
  o_userPreferences  OUT SYS_REFCURSOR
)
IS
BEGIN

  BEGIN
    OPEN o_userPreferences FOR
      SELECT  TRIM(pref_key)    AS pref_key
             ,TRIM(pref_value)  AS prev_value
      FROM    user_preference
      WHERE   LOWER(TRIM(user_id)) = LOWER(TRIM(i_userId))
      ;

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE o_userPreferences;
      RAISE;

  END;
  
END get_preferences;


-------------------------------------------------------------------------------
FUNCTION get_preference
(
  i_userId    IN  VARCHAR2,
  i_prefKey   IN  VARCHAR2
)
RETURN VARCHAR2
IS
  v_prefValue  user_preference.pref_value%TYPE;
BEGIN

  SELECT  TRIM(pref_value) INTO v_prefValue
  FROM    user_preference
  WHERE   LOWER(TRIM(user_id)) = LOWER(TRIM(i_userId))
  AND     LOWER(TRIM(pref_key)) = LOWER(TRIM(i_prefKey))
  ;

  RETURN v_prefValue;
  
END get_preference;


-------------------------------------------------------------------------------
PROCEDURE set_preference
(
  i_userId     IN  VARCHAR2,
  i_prefKey    IN  VARCHAR2,
  i_prefValue  IN  VARCHAR2
)
IS
  v_userId        VARCHAR2(20) := LOWER(TRIM(i_userId));
  v_prefKey       user_preference.pref_key%TYPE := LOWER(TRIM(i_prefKey));
  v_prefValue     user_preference.pref_key%TYPE := LOWER(TRIM(i_prefValue));
  v_currPrefValue user_preference.pref_key%TYPE;
BEGIN

  BEGIN
    -- Check for current preference value.
    v_currPrefValue := get_preference(v_userId, v_prefKey);
    
    -- No exception, so key exists.

    -- Compare current value to new value (only update if different).
    IF (LOWER(TRIM(v_currPrefValue)) != v_prefValue) THEN
      -- Update existing preference value.
      UPDATE  user_preference
      SET     pref_value = TRIM(i_prefValue)
             ,last_modified_dt = SYSDATE
      WHERE   LOWER(TRIM(user_id)) = v_userId
      AND     LOWER(TRIM(pref_key)) = v_prefKey
      ;
      IF (SQL%ROWCOUNT != 1) THEN
        RAISE_APPLICATION_ERROR(-20201, 'Unable to update preference value in user_preference table.');
      END IF;
      COMMIT;
    END IF;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Insert new preference key/value.
      INSERT INTO user_preference
      (user_id, pref_key, pref_value, last_modified_dt)
      VALUES
      (v_userId, TRIM(i_prefKey), TRIM(i_prefValue), SYSDATE)
      ;
      IF (SQL%ROWCOUNT != 1) THEN
        RAISE_APPLICATION_ERROR(-20200, 'Unable to insert new preference into user_preference table.');
      END IF;
      COMMIT;
  END;
  
END set_preference;




--============ package initialization =========================================
BEGIN
  -- Package initialization logic
  NULL;
  
END pack_User_Preference;
