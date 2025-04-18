--------------------------------------------------------
--  Constraints for Table EMPLOYEES
--------------------------------------------------------

  ALTER TABLE "HR"."EMPLOYEES" MODIFY ("LAST_NAME" CONSTRAINT "EMP_LAST_NAME_NN" NOT NULL ENABLE);
  ALTER TABLE "HR"."EMPLOYEES" MODIFY ("EMAIL" CONSTRAINT "EMP_EMAIL_NN" NOT NULL ENABLE);
  ALTER TABLE "HR"."EMPLOYEES" MODIFY ("HIRE_DATE" CONSTRAINT "EMP_HIRE_DATE_NN" NOT NULL ENABLE);
  ALTER TABLE "HR"."EMPLOYEES" MODIFY ("JOB_ID" CONSTRAINT "EMP_JOB_NN" NOT NULL ENABLE);
  ALTER TABLE "HR"."EMPLOYEES" ADD CONSTRAINT "EMP_SALARY_MIN" CHECK (salary > 0) ENABLE;
  ALTER TABLE "HR"."EMPLOYEES" ADD CONSTRAINT "EMP_EMAIL_UK" UNIQUE ("EMAIL")
  USING INDEX  ENABLE;
  ALTER TABLE "HR"."EMPLOYEES" ADD CONSTRAINT "EMP_EMP_ID_PK" PRIMARY KEY ("EMPLOYEE_ID")
  USING INDEX "HR"."EMP_EMP_ID_PK"  ENABLE;
