/* SQL-like description of the Berkeley DBs 
   created by MPTP.
   Serves mainly for reference, the code should respect 
   this structure. Maybe BNF would be better just for 
   description, but this can be used for SQL-like things. */

-- USE mptpdb;

/* Theorems */

CREATE TABLE theorems.db (

  formula		BLOB,           	/* In DFG, true for canceled */
  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g, t3_canceled_tarski */
  theorem_id		SMALLINT UNSIGNED,	/* Number in article */
  canceled		BOOL,			/* Canceled or not */
  article		VARCHAR(8),		/* Article string */
)

/* Top-level assertions, that are not theorems 
   (i.e. not ecported) */

CREATE TABLE private.db (

  formula		BLOB,           	/* In DFG  */
  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. a1_card_1 */
  private_id		SMALLINT UNSIGNED,	/* Number in article */
  article		VARCHAR(8),		/* Article string */
)

/* Lemmas are assertions in the proofs, 
   that have their own subproof. 
   They can be in one table - not so much. */

CREATE TABLE lemmas.db (

  formula		BLOB,           	/* In DFG  */
  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. l1_card_1 */
  lemma_id		SMALLINT UNSIGNED,	/* Number in article */
  article		VARCHAR(8),		/* Article string */
)

/* 'By' assertions - single steps verified by the checker.
    They go into a separate table for each article. */

CREATE TABLE <article_name>.by (

  formula		BLOB,           	/* In DFG  */
  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. b1_card_1 */
  by_id			SMALLINT UNSIGNED,	/* Number in article */
  article		VARCHAR(8),		/* Article string */
)


/* References for theorems */

CREATE TABLE references.db (

  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_' */
  theorem_id		SMALLINT UNSIGNED,	/* Number in article */
  canceled		BOOL,			/* Canceled or not */
  article		VARCHAR(8),		/* Article string */

  start_line		INT UNSIGNED,		/* Start line of the proof */
  start_col		INT UNSIGNED,		/* Start column of the proof */
  end_line		INT UNSIGNED,		/* End line of the proof */
  end_col		INT UNSIGNED,		/* End column of the proof */

  mizar_proof_length    INT UNSIGNED,           /* Number of all proof refs 
						   with repetition  */
  direct_references	BLOB			/* List of library refs used */
)

/* References for private */

CREATE TABLE privaterefs.db (

  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. a1_card_1 */
  private_id		SMALLINT UNSIGNED,	/* Number in article */
  article		VARCHAR(8),		/* Article string */

  start_line		INT UNSIGNED,		/* Start line of the proof */
  start_col		INT UNSIGNED,		/* Start column of the proof */
  end_line		INT UNSIGNED,		/* End line of the proof */
  end_col		INT UNSIGNED,		/* End column of the proof */

  mizar_proof_length    INT UNSIGNED,           /* Number of all proof refs 
						   with repetition  */
  direct_references	BLOB			/* List of library refs used */
)

/* References for lemmas */

CREATE TABLE lemmarefs.db (

  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. l1_card_1 */
  lemma_id		SMALLINT UNSIGNED,	/* Number in article */
  article		VARCHAR(8),		/* Article string */

  start_line		INT UNSIGNED,		/* Start line of the proof */
  start_col		INT UNSIGNED,		/* Start column of the proof */
  end_line		INT UNSIGNED,		/* End line of the proof */
  end_col		INT UNSIGNED,		/* End column of the proof */

  mizar_proof_length    INT UNSIGNED,           /* Number of all proof refs 
						   with repetition  */
  direct_references	BLOB			/* List of library refs used */
)

/* References for 'by' steps */

CREATE TABLE <article_name>.brefs (

  problem		VARCHAR(255),           /* Indexed by mml order */

  /* problem has following parts joined by '_', e.g. b1_card_1 */
  by_id		SMALLINT UNSIGNED,		/* Number in article */
  article		VARCHAR(8),		/* Article string */

  /* No start position, 'by' are just one-point */
  end_line		INT UNSIGNED,		/* End line of the proof */
  end_col		INT UNSIGNED,		/* End column of the proof */

  mizar_proof_length    INT UNSIGNED,           /* Number of all proof refs 
						   with repetition  */
  direct_references	BLOB			/* List of library refs used */
)
