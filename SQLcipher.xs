#define PERL_NO_GET_CONTEXT

#include "SQLcipherXS.h"

DBISTATE_DECLARE;

MODULE = DBD::SQLcipher          PACKAGE = DBD::SQLcipher::db

PROTOTYPES: DISABLE

BOOT:
    init_cxt();
    sv_setpv(get_sv("DBD::SQLcipher::sqlite_version",        TRUE|GV_ADDMULTI), SQLITE_VERSION);
    sv_setiv(get_sv("DBD::SQLcipher::sqlite_version_number", TRUE|GV_ADDMULTI), SQLITE_VERSION_NUMBER);

void
_do(dbh, statement)
    SV *dbh
    SV *statement
    CODE:
    {
        D_imp_dbh(dbh);
        IV retval;
        retval = sqlite_db_do_sv(dbh, imp_dbh, statement);
        /* remember that dbd_db_do_sv must return <= -2 for error     */
        if (retval == 0)            /* ok with no rows affected     */
            XST_mPV(0, "0E0");      /* (true but zero)              */
        else if (retval < -1)       /* -1 == unknown number of rows */
            XST_mUNDEF(0);          /* <= -2 means error            */
        else
            XST_mIV(0, retval);     /* typically 1, rowcount or -1  */
    }

IV
last_insert_rowid(dbh)
    SV *dbh
    ALIAS:
        DBD::SQLcipher::db::sqlite_last_insert_rowid = 1
    CODE:
    {
        D_imp_dbh(dbh);
        RETVAL = (IV)sqlite3_last_insert_rowid(imp_dbh->db);
    }
    OUTPUT:
        RETVAL

static int
create_function(dbh, name, argc, func, flags = 0)
    SV *dbh
    char *name
    int argc
    SV *func
    int flags
    ALIAS:
        DBD::SQLcipher::db::sqlite_create_function = 1
    CODE:
    {
        RETVAL = sqlite_db_create_function(aTHX_ dbh, name, argc, func, flags );
    }
    OUTPUT:
        RETVAL

#ifndef SQLITE_OMIT_LOAD_EXTENSION

static int
enable_load_extension(dbh, onoff)
    SV *dbh
    int onoff
    ALIAS:
        DBD::SQLcipher::db::sqlite_enable_load_extension = 1
    CODE:
    {
        RETVAL = sqlite_db_enable_load_extension(aTHX_ dbh, onoff );
    }
    OUTPUT:
        RETVAL

static int
load_extension(dbh, file, proc = 0)
    SV *dbh
    const char *file
    const char *proc
    ALIAS:
        DBD::SQLcipher::db::sqlite_load_extension = 1
    CODE:
    {
        RETVAL = sqlite_db_load_extension(aTHX_ dbh, file, proc);
    }
    OUTPUT:
        RETVAL

#endif

static int
create_aggregate(dbh, name, argc, aggr, flags = 0)
    SV *dbh
    char *name
    int argc
    SV *aggr
    int flags
    ALIAS:
        DBD::SQLcipher::db::sqlite_create_aggregate = 1
    CODE:
    {
        RETVAL = sqlite_db_create_aggregate(aTHX_ dbh, name, argc, aggr, flags );
    }
    OUTPUT:
        RETVAL

static int
create_collation(dbh, name, func)
    SV *dbh
    char *name
    SV *func
    ALIAS:
        DBD::SQLcipher::db::sqlite_create_collation = 1
    CODE:
    {
        RETVAL = sqlite_db_create_collation(aTHX_ dbh, name, func );
    }
    OUTPUT:
        RETVAL


static void
collation_needed(dbh, callback)
    SV *dbh
    SV *callback
    ALIAS:
        DBD::SQLcipher::db::sqlite_collation_needed = 1
    CODE:
    {
        sqlite_db_collation_needed(aTHX_ dbh, callback );
    }


static int
progress_handler(dbh, n_opcodes, handler)
    SV *dbh
    int n_opcodes
    SV *handler
    ALIAS:
        DBD::SQLcipher::db::sqlite_progress_handler = 1
    CODE:
    {
        RETVAL = sqlite_db_progress_handler(aTHX_ dbh, n_opcodes, handler );
    }
    OUTPUT:
        RETVAL

static int
sqlite_trace(dbh, callback)
    SV *dbh
    SV *callback
    CODE:
    {
        RETVAL = sqlite_db_trace(aTHX_ dbh, callback );
    }
    OUTPUT:
        RETVAL

static int
profile(dbh, callback)
    SV *dbh
    SV *callback
    ALIAS:
        DBD::SQLcipher::db::sqlite_profile = 1
    CODE:
    {
        RETVAL = sqlite_db_profile(aTHX_ dbh, callback );
    }
    OUTPUT:
        RETVAL

SV*
commit_hook(dbh, hook)
    SV *dbh
    SV *hook
    ALIAS:
        DBD::SQLcipher::db::sqlite_commit_hook = 1
    CODE:
    {
        RETVAL = (SV*) sqlite_db_commit_hook( aTHX_ dbh, hook );
    }
    OUTPUT:
        RETVAL

SV*
rollback_hook(dbh, hook)
    SV *dbh
    SV *hook
    ALIAS:
        DBD::SQLcipher::db::sqlite_rollback_hook = 1
    CODE:
    {
        RETVAL = (SV*) sqlite_db_rollback_hook( aTHX_ dbh, hook );
    }
    OUTPUT:
        RETVAL

SV*
update_hook(dbh, hook)
    SV *dbh
    SV *hook
    ALIAS:
        DBD::SQLcipher::db::sqlite_update_hook = 1
    CODE:
    {
        RETVAL = (SV*) sqlite_db_update_hook( aTHX_ dbh, hook );
    }
    OUTPUT:
        RETVAL


static int
set_authorizer(dbh, authorizer)
    SV *dbh
    SV *authorizer
    ALIAS:
        DBD::SQLcipher::db::sqlite_set_authorizer = 1
    CODE:
    {
        RETVAL = sqlite_db_set_authorizer( aTHX_ dbh, authorizer );
    }
    OUTPUT:
        RETVAL


int
busy_timeout(dbh, timeout=NULL)
    SV *dbh
    SV *timeout
    ALIAS:
        DBD::SQLcipher::db::sqlite_busy_timeout = 1
    CODE:
        RETVAL = sqlite_db_busy_timeout(aTHX_ dbh, timeout );
    OUTPUT:
        RETVAL

static int
backup_from_file(dbh, filename)
    SV *dbh
    char *filename
    ALIAS:
        DBD::SQLcipher::db::sqlite_backup_from_file = 1
    CODE:
        RETVAL = sqlite_db_backup_from_file(aTHX_ dbh, filename);
    OUTPUT:
        RETVAL

static int
backup_to_file(dbh, filename)
    SV *dbh
    char *filename
    ALIAS:
        DBD::SQLcipher::db::sqlite_backup_to_file = 1
    CODE:
        RETVAL = sqlite_db_backup_to_file(aTHX_ dbh, filename);
    OUTPUT:
        RETVAL

HV*
table_column_metadata(dbh, dbname, tablename, columnname)
    SV* dbh
    SV* dbname
    SV* tablename
    SV* columnname
    ALIAS:
        DBD::SQLcipher::db::sqlite_table_column_metadata = 1
    CODE:
        RETVAL = sqlite_db_table_column_metadata(aTHX_ dbh, dbname, tablename, columnname);
    OUTPUT:
        RETVAL

SV*
db_filename(dbh)
    SV* dbh
    ALIAS:
        DBD::SQLcipher::db::sqlite_db_filename = 1
    CODE:
        RETVAL = sqlite_db_filename(aTHX_ dbh);
    OUTPUT:
        RETVAL

static int
register_fts3_perl_tokenizer(dbh)
    SV *dbh
    ALIAS:
        DBD::SQLcipher::db::sqlite_register_fts3_perl_tokenizer = 1
    CODE:
        RETVAL = sqlite_db_register_fts3_perl_tokenizer(aTHX_ dbh);
    OUTPUT:
        RETVAL

HV*
db_status(dbh, reset = 0)
    SV* dbh
    int reset
    ALIAS:
        DBD::SQLcipher::db::sqlite_db_status = 1
    CODE:
        RETVAL = (HV*)_sqlite_db_status(aTHX_ dbh, reset);
    OUTPUT:
        RETVAL


static int
create_module(dbh, name, perl_class)
    SV *dbh
    char *name
    char *perl_class
    ALIAS:
        DBD::SQLcipher::db::sqlite_create_module = 1
    CODE:
    {
        RETVAL = sqlite_db_create_module(aTHX_ dbh, name, perl_class);
    }
    OUTPUT:
        RETVAL


MODULE = DBD::SQLcipher          PACKAGE = DBD::SQLcipher::st

PROTOTYPES: DISABLE

HV*
st_status(sth, reset = 0)
    SV* sth
    int reset
    ALIAS:
        DBD::SQLcipher::st::sqlite_st_status = 1
    CODE:
        RETVAL = (HV*)_sqlite_st_status(aTHX_ sth, reset);
    OUTPUT:
        RETVAL

MODULE = DBD::SQLcipher          PACKAGE = DBD::SQLcipher

# a couple of constants exported from sqlite3.h

PROTOTYPES: DISABLE

static int
compile_options()
    CODE:
        int n = 0;
        AV* av = (AV*)sqlite_compile_options();
        if (av) {
            int i;
            n = av_len(av) + 1;
            EXTEND(sp, n);
            for (i = 0; i < n; i++) {
                PUSHs(AvARRAY(av)[i]);
            }
        }
        XSRETURN(n);

HV*
sqlite_status(reset = 0)
    int reset
    CODE:
        RETVAL = (HV*)_sqlite_status(reset);
    OUTPUT:
        RETVAL

INCLUDE: constants.inc
INCLUDE: SQLcipher.xsi
