USE mptpresults;

/* Proposed structure of the database of results for MPTP */


/* Problem info independent of prover runs */

CREATE TABLE probleminfo (

  problem		VARCHAR(255),           /* Index on initial 20 chars */
  article		VARCHAR(8),		/* Article string */
  theorem_id		SMALLINT UNSIGNED,	/* Number in article */

  mizar_proof_length    INT UNSIGNED,		
  direct_references_nr  INT UNSIGNED,		/* Without bg theory */
  direct_references	BLOB,			/* List of their names */
  bg_references_nr	INT UNSIGNED,		/* bg theory */
  bg_references		BLOB,			/* List of their names */
  all_references_nr	INT UNSIGNED,		/* With bg theory */

  conjecture_syms_nr	INT UNSIGNED,
  conjecture_syms	BLOB,
  direct_refs_syms_nr	INT UNSIGNED,
  direct_refs_syms	BLOB,
  problem_syms_nr	INT UNSIGNED,
  problem_syms		BLOB,			/* All symbols */

  INDEX  xproblem 		(problem(20)), 
  INDEX  xarticle 		(article),
  INDEX  xtheorem_id 		(theorem_id),
  INDEX  xmizar_proof_length 	(mizar_proof_length),
  INDEX  xdirect_references_nr 	(direct_references_nr),
  INDEX  xbg_references_nr 	(bg_references_nr),	
  INDEX  xall_references_nr 	(all_references_nr),
  INDEX  xdirect_refs_syms_nr 	(direct_refs_syms_nr),
  INDEX  xproblem_syms_nr 	(problem_syms_nr)
);


/* Additional problem info for proved tasks */

CREATE TABLE proved (

/* Primary problem identification */
  id		        INT NOT NULL AUTO_INCREMENT,
  problem		VARCHAR(255),           /* Index on initial 20 chars */
  article		VARCHAR(8),		/* Article string */
  theorem_id		SMALLINT UNSIGNED,	/* Number in article */
  format		ENUM('DFG','TPTP',
			     'LOP','OTTER'),
  prover		VARCHAR(255),		/* Name and version */

/* Result info */

  result		ENUM('PROOF','COMPLETION',
			     'TIMELIMIT','MEMLIMIT',
			     'KILLED','CRASH','UNKNOWN'),
  proof_depth		INT UNSIGNED,
  proof_length		INT UNSIGNED,
  clauses_derived	INT UNSIGNED,
  clauses_backtracked	INT UNSIGNED,
  clauses_kept		INT UNSIGNED,
  memory_allocated	INT UNSIGNED,		/* In kb */
  time			INT UNSIGNED,		/* In seconds */
  input_time		INT UNSIGNED,		/* In seconds */
  flotter_time		INT UNSIGNED,		/* In seconds */
  inferences_time	INT UNSIGNED,		/* In seconds */
  backtracking_time	INT UNSIGNED,		/* In seconds */
  reduction_time	INT UNSIGNED,		/* In seconds */

/* Processing info */

  time_limit		INT UNSIGNED,		/* In seconds */
  memory_limit		INT UNSIGNED,		/* In kb */
  prover_parameters	BLOB,
  start_date		DATE,
  hostname		VARCHAR(255),
  machine_cpu		VARCHAR(255),
  machine_memory	INT UNSIGNED,		/* In kb */
  machine_os		VARCHAR(255),

/* Additional result info */

/* used_input_flas_nr = used_dir_refs_nr + used_bg_flas_nr */

  used_input_flas_nr	INT UNSIGNED,
  used_input_flas	BLOB,			/* List of their names */
  used_dir_refs_nr	INT UNSIGNED,
  used_dir_refs	BLOB,			/* List of their names */
  used_bg_flas_nr	INT UNSIGNED,
  used_bg_flas		BLOB,			/* List of their names */

/* not yet */
--  used_syms_nr		INT UNSIGNED,
--  used_syms		BLOB,			/* Only if in the proof */

  PRIMARY KEY ( id ),
  INDEX  xproblem 		(problem(20)), 
  INDEX  xarticle 		(article),
  INDEX  xtheorem_id 		(theorem_id),
  INDEX  xprover 		(prover),
  INDEX  xproof_length 		(proof_length),
  INDEX  xclauses_derived 	(clauses_derived),
  INDEX  xtime 			(time),
  INDEX  xstart_date 		(start_date),
  INDEX  xused_input_flas_nr 	(used_input_flas_nr),
  INDEX  xused_dir_refs_nr  	(used_dir_refs_nr),
  INDEX  xused_bg_flas_nr  	(used_bg_flas_nr)	
);

/* Proof info is in separate table - it is not supposed to
   be accessed too often 
*/

CREATE TABLE proof (

/* id is common with the proved table */
  id		        INT NOT NULL AUTO_INCREMENT,
  problem		VARCHAR(255),	/* Just consistency check */
  proof			MEDIUMBLOB,	/* About 17M should be enough */
  PRIMARY KEY ( id )
);


/* Basically as proved, but some result info missing */

CREATE TABLE unproved (

/* Primary problem identification */
  id		        INT NOT NULL AUTO_INCREMENT,
  problem		VARCHAR(255),		/* Index on initial 20 chars */
  article		VARCHAR(8),		/* Article string */
  theorem_id		SMALLINT UNSIGNED,	/* Number in article */
  format		ENUM('DFG','TPTP',
			     'LOP','OTTER'),
  prover		VARCHAR(255),		/* Name and version */

/* Result info */

  result		ENUM('PROOF','COMPLETION',
			     'TIMELIMIT','MEMLIMIT',
			     'KILLED','CRASH', 'UNKNOWN'),
/*  proof_depth		INT UNSIGNED,
    proof_length		INT UNSIGNED,
*/
  clauses_derived	INT UNSIGNED,
  clauses_backtracked	INT UNSIGNED,
  clauses_kept		INT UNSIGNED,
  memory_allocated	INT UNSIGNED,		/* In kb */
  time			INT UNSIGNED,		/* In seconds */
  input_time		INT UNSIGNED,		/* In seconds */
  flotter_time		INT UNSIGNED,		/* In seconds */
  inferences_time	INT UNSIGNED,		/* In seconds */
  backtracking_time	INT UNSIGNED,		/* In seconds */
  reduction_time	INT UNSIGNED,		/* In seconds */

/* Processing info */

  time_limit		INT UNSIGNED,		/* In seconds */
  memory_limit		INT UNSIGNED,		/* In kb */
  prover_parameters	BLOB,
  start_date		DATE,
  hostname		VARCHAR(255),
  machine_cpu		VARCHAR(255),
  machine_memory	INT UNSIGNED,		/* In kb */
  machine_os		VARCHAR(255),

/* Additional result info missing in this table */

  PRIMARY KEY ( id ),
  INDEX  xproblem 		(problem(20)), 
  INDEX  xarticle 		(article),
  INDEX  xtheorem_id 		(theorem_id),
  INDEX  xprover 		(prover),
  INDEX  xclauses_derived 	(clauses_derived),
  INDEX  xtime 			(time),
  INDEX  xstart_date 		(start_date)
);

/* Article background info independent of prover runs */

CREATE TABLE article_bg_info (

  article		VARCHAR(8),		/* Article string */

  bg_references_nr	INT UNSIGNED,		/* complete bg theory */

  bg_dco_nr		INT UNSIGNED,		/* constructor types bg */
  bg_dco		BLOB,			/* List of their names */
  bg_dem_nr		INT UNSIGNED,		/* mode existence bg */
  bg_dem		BLOB,			/* List of their names */
  bg_pro_nr		INT UNSIGNED,		/* properties bg */
  bg_pro		BLOB,			/* List of their names */
  bg_cle_nr		INT UNSIGNED,		/* cluster existence bg */
  bg_cle		BLOB,			/* List of their names */
  bg_clf_nr		INT UNSIGNED,		/* functor cluster bg */
  bg_clf		BLOB,			/* List of their names */
  bg_clc_nr		INT UNSIGNED,		/* condit. cluster bg */
  bg_clc		BLOB,			/* List of their names */
  bg_dre_nr		INT UNSIGNED,		/* requirements bg */
  bg_dre		BLOB,			/* List of their names */

  bg_syms_nr		INT UNSIGNED,
  bg_syms		BLOB,			/* All symbols */

  PRIMARY KEY ( article ),
  INDEX xbg_references_nr	(bg_references_nr),
  INDEX xbg_dco_nr		(bg_dco_nr),
  INDEX xbg_dem_nr		(bg_dem_nr),
  INDEX xbg_pro_nr		(bg_pro_nr),
  INDEX xbg_cle_nr		(bg_cle_nr),
  INDEX xbg_clf_nr		(bg_clf_nr),
  INDEX xbg_clc_nr		(bg_clc_nr),
  INDEX xbg_dre_nr		(bg_dre_nr),
  INDEX xbg_syms_nr		(bg_syms_nr)
);
