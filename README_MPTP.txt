MPTP version 0.1

All checker problems ("bys") are now available for reproofs and 
all theorems too.

The checker problems should be the easy ones, while
the theorem problems should be usually very hard.
You can get an approximate idea of their hardness by looking at the
number of references (the fourth column in the references table - it
counts also all private references inside the proof, not just external).

There are now several reasons, why a problem may be impossible
to prove:
 - For checker problems, second order constants may occur in the
  translated formulas. These are symbols starting with 'f'
  (functions) and 'p' (predicates), so e.g. if there is 'f1'
  present in some formula, this is the case.
  This happens in proofs of schemes.
  The type theorems for such constants are not exported as
  a part of the problem (in this version; it will be fixed),
  and it may cause unprovability. However, in many cases,
  the type theorem is not necessary, so the problem will be 
  provable.
  If you want to be safe from this, do not try any checker
  problems that give nonzero grep count for "\b[fp][0-9]\+\b".


 - For theorem problems, the problem consists of all external
  references given in the proof. As a rule, these are just
  references to other theorems and definitions, which is ok.
  However, a scheme reference (starting with 's') and private 
  reference (starting with 'a') may rarely occur too.
  This is caused either by scheme justifications inside the proof,
  or by unexported top-level proposition in the article, used
  in the proof.
  Both are not difficult to fix (and hopefully will in future 
  versions).
  If you want to be safe from this, do not try any theorem
  problems whose references match "\b[as][0-9]\+".
  As a default, the problem creating script now
  omits such theorems and prints a message about it.
  About one quarter of all theorems have such bad references,
  so there are still about 27000 theorems left for export.

 - Additionally for theorem problems, the "definitions" directive
  is now neglected. Other possibility is to add all definitions
  from articles in this directive, which seems worse (too much
  of them). The proper treatment will detect definitional 
  expansions inside proofs, and include such definitions among
  references.


 - Numbers are treated in a special way by Mizar, while
  we export them only very simply in this version.

 - The "setof" (Fraenkel) operator is a second-order construct
  that is allowed in the Mizar language. This can also be 
  fixed quite easily, but the fix did not make it to this
  version. So now all "setof" terms are very simply translated
  into the constant "setof/0". In some cases this may be quite
  strong, however, it may also be still insufficient when 
  compared with the Mizar checker, which handles it specially.
  So the problem may turn out to be too easy, or unprovable.
  Exclude them by grepping for "setof".

 - The Mizar structures can cause problems now.
  On one hand, the Mizar structures are a bit underspecified
  objects (see some discussion on the Mizar Forum on that). 
  On the other hand, if you define two structure types L1,L2 with
  exactly the same fields (so they differ just by the name of
  the structure type), then for X1 being strict L1, X2 being
  strict L2, such that X1 and X2 have exactly the same fields,
  Mizar will still be able to infer that X1 <> X2.
  This feels quite unnatural (and inconsistent with the usual
  interpretation of structures as functions), and I hope it
  will change in future releases of Mizar. Should this become
  too pressing matter, probably some disequality axioms
  would have to be added.


  
Description of the exported database:

All the databases should be clean both for fast (and memory efficient) 
DB (Berkeley Database) processing, and for Prolog processing
(definitely not memory efficient). The problem creating script 
accesses the files as databases (of the DB kind RECNO), using the
Perl DB_File interface to DB (should be present with any normal Perl -
if not, look for rpm like "perl-DB_File" ).
Look at the script mkproblem.pl, if you want to write your own 
processing scripts using DB. 
Prolog is not used for anything (and not planned to), however I will 
try to maintain the Prolog cleanness, for people who want to do
cheap experimenting.

The checker problems are gzipped in the directory DB/BYS, and
the problem making scripts handle their decompression and
cleanup when needed.

theorems.db:     Theorems.
references.db:   Contains refernces needed for each theorem.
definitions.db:  Definitional theorems.
constrtypes.db:  Result types of constructors.
exmodes.db:	 Existential assertions for modes.
properties.db:	 Properties of constructors.
exclusters.db:	 Existential clusters.
funcclusters.db: Functor clusters.
condclusters.db: Conditional clusters.
requirements.db: Requirements.
funcarities.db:  Keeps arities of functions (in first-order sense
		 i.e. selectors and others too) created in the articles.
		 The format is: arity(k3_absvalue,1).
predarities.db:  Keeps arities for predicates.
environments.db: This db contains info on each article's environment 
		 directives, so it is :
		 env(dirVocabulary,dirNotations, dirDefinitions,dirTheorems,
		  dirSchemes,dirClusters, dirConstructors,dirRequirements,
		  dirProperties).
		 Since the dirConstructors behaves recursively, we keep
		 its transitive closure already here.

counts.db:      Contains for each article counts of its various items, 
		the format is:
	        counts(thcount, defcount, constrtypcount, exmodecount,
	               propcount, exclcount, funcclcount,
		       condclcount, funcarcount, predarcount,
		       reqcount, bycount, articlename).
	         articlename is implicit by the position in the file, 
		 but is present anyway for crosschecking.
          
runningcounts.db: Is a version of counts.db with running sums. This
		  is used for fast access into the databases.



Scripts:

mkproblem.pl: Gets a list of options and a list of theorem names or
	      checker problem names (in our format, e.g. "t39_absvalue" or
	      "by_25_16_absvalue"), and produces
	      a complete dfg file for each of them. This file
	      contains (mostly) full informations necessary for 
	      reproval, i.e. the references and all of the background
	      info (constructor types, requirements, etc.).

	      












