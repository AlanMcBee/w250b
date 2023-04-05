// *****************************************************************************************************************************
// This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
// *****************************************************************************************************************************

// ==========
// PARAMETERS
// ==========

@description('Date and time of deployment creation (UTC) in ISO 8601 format (yyyyMMddTHHmmssZ). Default = current UTC date and time. Using the default is very strongly recommended')
param Arm_DeploymentCreationDateTime string = utcNow()

// CDPH-specific parameters
// ------------------------

@description('CDPH Business Unit (numbers & digits only)')
@maxLength(5)
@minLength(2)
param Cdph_BusinessUnit string

@description('CDPH Business Unit Program (numbers & digits only)')
@maxLength(7)
@minLength(2)
param Cdph_BusinessUnitProgram string

@description('Targeted deployment environment')
@allowed([
  'dev'
  'test'
  'stage'
  'prod'
])
param Cdph_Environment string

// =========
// VARIABLES
// =========

// CDPH-specific variables
// -----------------------

var cdph_CommonTags = {
  'ACCOUNTABILITY-Business Unit': Cdph_BusinessUnit
  'ACCOUNTABILITY-Cherwell Change Control': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Cost Center': '' // TODO: parameterize or remove?
  'ACCOUNTABILITY-Date Created': Arm_DeploymentCreationDateTime
  'ACCOUNTABILITY-Owner': Cdph_BusinessUnit
  'ACCOUNTABILITY-Program': Cdph_BusinessUnitProgram
  'SECURITY-Criticality': '' // TODO: parameterize or remove?
  'SECURITY-Facing': '' // TODO: parameterize or remove?
  ENVIRONMENT: Cdph_Environment
}

output out_Cdph_CommonTags object = cdph_CommonTags
