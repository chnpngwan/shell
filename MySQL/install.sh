#!/bin/bash

#download mysql package
package="/opt/mysql-8.0.27-linux-glibc2.12-x86_64.tar.xz"
echo -n "please input start_port:"
read start_port
echo -n "please input end_port:"
read end_port
pts=$(seq ${start_port} ${end_port})
echo -n "please input innodb_pool_size,eg 512M,2G:"
read pool_size
innodb_pool_size=${pool_size}
echo -n "please input data_base dir:"
read base_dir
data_root=${base_dir}
#test network connecting
ping -c 3 www.baidu.com
if test $? -eq 0; then
    mkdir software && cd software
#download package
fi
#create mysql user and group
if test $(cat /etc/passwd | grep mysql); then
    echo "mysql user already exist"
else
    useradd -M -s /sbin/nologin mysql
fi
#unzip mysql package
xz -dk $package
tar -xvf $(basename ${package} .xz)
package_dir=$(basename ${package} .tar.xz)
for pt in $pts; do
    mkdir -p ${data_root}/$pt
    cp -rpf ${package_dir}/* ${data_root}/$pt && mkdir -p ${data_root}/$pt/data
    chown -R mysql:mysql ${data_root}/$pt
    #config mysql configfile
    cat >/etc/my$pt.cnf <<EOF
[mysql]
auto-rehash
socket                              =${data_root}/$pt/data/mysql$pt.sock                #  /tmp/mysql.sock
[mysqld]
####: for global
user                                =mysql
server_id                          =$pt                          # 1
port                                =$pt
mysqlx                              =0
basedir                            =${data_root}/$pt/            # /usr/local/mysql/
datadir                            =${data_root}/$pt/data    # /usr/local/mysql/data/
max_prepared_stmt_count            =1048576                        # 16382
open_files_limit                    =65536                          # 65536
socket                              =${data_root}/$pt/data/mysql$pt.sock                # /tmp/mysql.sock
skip_name_resolve                  =1                              #  0
super_read_only                    =OFF                            # OFF
sql_require_primary_key            =ON                            # OFF
cte_max_recursion_depth            =1000                          # 1000
log_timestamps                      =system                        # UTC
lower_case_table_names              =1                              # 0
auto_increment_increment            =1                              # 1
auto_increment_offset              =1                              # 1
lock_wait_timeout                  =31536000                      # ! for metadata lock wait
event_scheduler                    =OFF                            # ON
auto_generate_certs                =ON                            # ON
big_tables                          =OFF                            # OFF ! for TempTable storage engine
join_buffer_size                    =256k                          # 0.25M
activate_all_roles_on_login        =ON                            # OFF
end_markers_in_json                =OFF                            # OFF
tmpdir                              =/tmp/
max_connections                    =512                            # 151
autocommit                          =ON                            # ON
sort_buffer_size                    =262144                        # 262144(256k) ! fix too many Sort_merge_passes per second
#                                                                    # in SHOW GLOBAL STATUS output; speed up ORDER BY or GROUP BY operations
####: for table cache
table_open_cache                    =4000                          #  2000
table_definition_cache              =2000                          #  1400
table_open_cache_instances          =32                            #  16
####: for net
max_allowed_packet                  =64M                            # 64M
bind_address                        =*                              # *
connect_timeout                    =10                            # 10
interactive_timeout                =28800                          # 28800
net_read_timeout                    =30                            # 30
net_retry_count                    =10                            # 10
net_write_timeout                  =60                            # 60
net_buffer_length                  =32k                            # 16384(16k)
####: for logs
log_output                          =FILE                          # FILE
##  -- general log
general_log                        =OFF                            # OFF
general_log_file                    =general.log                    # hotname.log
##  -- error log
log_error                          =err.log                        # stderr
log_statements_unsafe_for_binlog    =ON                            # ! for error 1592
##  -- slow log
long_query_time                          =2.0                      # 10.000000
log_queries_not_using_indexes            =OFF                      # OFF
log_slow_admin_statements                =OFF                      # OFF
log_slow_slave_statements                =OFF                      # OFF
slow_query_log                          =ON                        # OFF
slow_query_log_file                      =slow.log                  # slow.log
####: for binlog
log_bin                                      =mysql-bin
binlog_checksum                              =none                          # CRC32
log_bin_trust_function_creators              =ON                            # OFF
binlog_direct_non_transactional_updates      =OFF                          # OFF
binlog_expire_logs_seconds                    =604800                        # 2592000(30days) | 604800(7days)
binlog_error_action                          =ABORT_SERVER                  # ABORT_SERVER | IGNORE_ERROR
binlog_format                                =ROW                          # ROW | STATEMENT | MIXED
max_binlog_stmt_cache_size                    =1G                            # 18446744073709547520
max_binlog_cache_size                        =1G                            # 18446744073709547520(1G)
max_binlog_size                              =1G
binlog_order_commits                          =ON                            # ON
binlog_row_image                              =FULL                          # FULL | MINIMAL | NOBLOB
binlog_row_metadata                          =MINIMAL                      # MINIMAL | FULL
binlog_rows_query_log_events                  =ON                            # OFF
sync_binlog                                  =1                            # 1 | 0 | N
binlog_stmt_cache_size                        =32k                          # 32768(32k)
log_slave_updates                            =ON                            # ON
binlog_group_commit_sync_delay                =4000                          # 0
binlog_group_commit_sync_no_delay_count      =10                            # 0
binlog_cache_size                            =96k                          # 32768(32k)
binlog_transaction_dependency_history_size    =25000                        # 25000
binlog_transaction_dependency_tracking        =WRITESET                      # COMMIT_ORDER | WRITESET | WRITESET_SESSION
####: for storage engine
default_storage_engine                        =innodb                      # InnoDB
default_tmp_storage_engine                    =innodb                      # InnoDB
internal_tmp_mem_storage_engine              =TempTable                    # TempTable
####: for innodb
## disk I/O and file space management
innodb_data_home_dir                =./                            # ./
innodb_data_file_path              =ibdata1:256M;ibdata2:256M:autoextend        # ibdata1:12M:autoextend
innodb_page_size                    =16k                            # 16384(16k)
innodb_default_row_format          =dynamic                        # dynamic | compact | redundant
innodb_log_group_home_dir          =./                            # ./
innodb_log_files_in_group          =8                              # 2
innodb_log_file_size                =128M                          # 50331648(48M)
innodb_log_buffer_size              =256M                          # 16777216(16M)
innodb_redo_log_encrypt            =OFF                            # OFF
innodb_online_alter_log_max_size    =128M                          # 134217728(128M)
innodb_undo_directory              =./                            # ./
innodb_undo_log_encrypt            =OFF                            # OFF
innodb_undo_log_truncate            =ON                            # ON
innodb_max_undo_log_size            =1G                            # 1073741824(1G)
innodb_rollback_on_timeout          =OFF                            # OFF
innodb_rollback_segments            =128                            # 128 [1~128]
innodb_log_checksums                =ON                            # ON
innodb_checksum_algorithm          =crc32                          # crc32
innodb_log_compressed_pages        =ON                            # ON
innodb_doublewrite                  =ON                            # ON  ! do not disable it please.
innodb_commit_concurrency          =0                              # 0
## configuring innodb  readonly
innodb_read_only                    =OFF                            # OFF
## configuring innodb dedicated server
innodb_dedicated_server            =OFF                            # OFF ! related to mysql auto config please donot chanage
## configuring innodb buffer pool size and instances
innodb_buffer_pool_chunk_size      =128M                          # 134217728(128M)
innodb_buffer_pool_size            =${innodb_pool_size}                            # 134217728(128M)
innodb_buffer_pool_instances        =10                              # 1
## making the buffer pool scan resistant
innodb_old_blocks_pct              =37                            # 37
innodb_old_blocks_time              =1000                          # 1000
## configuring innodb buffer pool prefetching(read ahead)
innodb_random_read_ahead            =off                            # OFF
innodb_read_ahead_threshold        =56                            # 56
## configuring innodb buffer pool flushing
innodb_max_dirty_pages_pct_lwm      =20                            # 10
innodb_max_dirty_pages_pct          =90                            # 90
## fine-tuning innodb buffer pool flushing
innodb_flush_neighbors              =0                              # off | on (off for ssd ,on for hdd)
innodb_lru_scan_depth              =1024                          # 1024
## tuning for sharp checkpoint
innodb_adaptive_flushing            =ON                            # ON
innodb_adaptive_flushing_lwm        =10                            # 10
innodb_flushing_avg_loops          =30                            # 30(a heih value means adaptive flushing is slow)
## saving and restoring the buffer pool state
innodb_buffer_pool_dump_pct        =50                            # 50
innodb_buffer_pool_dump_at_shutdown =ON                            # ON
innodb_buffer_pool_load_at_startup  =ON                            # ON
innodb_buffer_pool_filename        =ib_buffer_pool                # ib_buffer_pool
innodb_stats_persistent            =ON                            # ON
innodb_stats_on_metadata            =ON                            # OFF
innodb_stats_method                =nulls_equal                    # nulls_equal
innodb_stats_auto_recalc            =ON                            # ON
innodb_stats_include_delete_marked  =ON                            # ON
innodb_stats_persistent_sample_pages=20                            # 20
innodb_stats_transient_sample_pages =8                              # 8
innodb_status_output                =OFF                            # OFF
innodb_status_output_locks          =OFF                            # OFF
innodb_buffer_pool_dump_now        =OFF                            # OFF
innodb_buffer_pool_load_abort      =OFF                            # OFF
innodb_buffer_pool_load_now        =OFF                            # OFF
## configuring thread concurrency for innodb
innodb_thread_concurrency          =0                              # 0
#? if innodb_thread_concurrency is 0, the value of innodb_thread_sleep_delay is ignored;
#? so default the next 3 are ignored.
innodb_concurrency_tickets          =5000                          # 5000
innodb_thread_sleep_delay          =15000                          # 4000  ( 4ms)
innodb_adaptive_max_sleep_delay    =150000                        # 150000 (15/100 s)
## configuring the number of background innoDB i/o threads
#? if you see more than 64 × innodb_read_io_threads pending read requests in
#? SHOW ENGINE INNODB STATUS output, you might improve performance
#? by increasing the value of innodb_read_io_threads.
innodb_read_io_threads              =4                              # 4
innodb_write_io_threads            =4                              # 4
## using asynchronous i/o on linux
#? 1):perform read-ahead and write requests for data file pages.
#? 2):Too many I/O write requests dispatched to the operating system for parallel processing could,
#? in some cases, result in I/O read starvation
innodb_use_native_aio              =ON                            # ON
## configuring the innodb master thread i/o rate
innodb_flush_sync                  =OFF                            # ON
#? To adhere to the limit on InnoDB background I/O activity defined by the innodb_io_capacity setting,
#? disable innodb_flush_sync.
innodb_io_capacity                  =4000                            # 200
innodb_io_capacity_max              =20000                          # 2000
## configuring spin lock polling
innodb_spin_wait_delay              =6                              # 6
## configuring innoDB purge scheduling
innodb_purge_threads                =4                              # 4
innodb_purge_batch_size            =300                            # 300(300 undo log page)
innodb_purge_rseg_truncate_frequency=128                            # 128
## --  Lock & Wait
innodb_deadlock_detect              =ON                            # ON
innodb_autoinc_lock_mode            =2                              # 0 | 1 | 2
innodb_print_all_deadlocks          =ON                            # OFF
innodb_lock_wait_timeout            =50                            # 50
innodb_table_locks                  =ON                            # ON
innodb_sync_array_size              =1                              # 1
innodb_sync_spin_loops              =30                            # 30
## innodb others
innodb_print_ddl_logs              =OFF                            # OFF
innodb_replication_delay            =0                              # 0
innodb_cmp_per_index_enabled        =OFF                            # ! do not enable it please.
innodb_disable_sort_file_cache      =OFF                            # OFF
innodb_numa_interleave              =OFF                            # OFF
innodb_strict_mode                  =ON                            # ON
innodb_sort_buffer_size            =1M                            # 1M(global and only for full-text search)
innodb_fast_shutdown                =1                              # 0 | 1 | 2
innodb_force_load_corrupted        =OFF                            # OFF
innodb_force_recovery              =0                              # 0 | 1 | 2 | 3 | 4 | 5 | 6
innodb_temp_tablespaces_dir        =./#innodb_temp/                # ./#innodb_temp/
innodb_tmpdir                      =./                            # ! the sort file temp dir of alter table opration
innodb_temp_data_file_path          =ibtmp1:64M:autoextend          # ibtmp1:12M:autoextend ! stores rollback segments for changes made to user-created temporary tables.
innodb_page_cleaners                =4                              # 1
## adaptive hash index
innodb_adaptive_hash_index          =ON                            # ON
innodb_adaptive_hash_index_parts    =8                              # 8
## -- Flush & Io
innodb_flush_log_at_timeout        =1                              # 1
innodb_flush_log_at_trx_commit      =1                              # 1 | 0 | 2
innodb_flush_method                =O_DIRECT                      # fsync | o_direct
innodb_fsync_threshold              =0                              # 0 ~ 2**64-1
innodb_change_buffer_max_size      =25                            # 25
innodb_change_buffering            =all                            # all | none | inserts | deletes | changes | purges
####: others
div_precision_increment            =4                              # 4
eq_range_index_dive_limit          =200                            # 200
explicit_defaults_for_timestamp    =ON                            # ON
group_concat_max_len                =1024                          # 1024
flush                              =OFF                            # OFF
flush_time                          =0                              # 0
automatic_sp_privileges            =ON                            # ON
innodb_fill_factor                  =90                            # 100
innodb_file_per_table              =ON                            # ON
innodb_autoextend_increment        =64                            # 64
innodb_open_files                  =64000                          # 4000
####: for authentication
caching_sha2_password_auto_generate_rsa_keys  =ON                            # ON
caching_sha2_password_private_key_path        =private_key.pem              # private_key.pem
caching_sha2_password_public_key_path        =public_key.pem                # public_key.pem
default_authentication_plugin                =caching_sha2_password        # caching_sha2_password
default_password_lifetime                    =0                            # 0
disconnect_on_expired_password                =ON                            # ON
####: for character
character_set_server                =utf8mb4                        # utf8mb4
collation_server                    =utf8mb4_0900_ai_ci            # utf8mb4_0900_ai_ci
####: for optimizer
optimizer_prune_level              =1
optimizer_search_depth              =62
optimizer_switch                    =index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=off,skip_scan=on
optimizer_trace                    =enabled=off,one_line=off
optimizer_trace_features            =greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on
optimizer_trace_limit              =1
optimizer_trace_max_mem_size        =1048576
optimizer_trace_offset              =-1                                                                                                                                                                                                                               
####  for performance_schema
performance_schema                                                      =on    #    on
performance_schema_consumer_global_instrumentation                      =on    #    on
performance_schema_consumer_thread_instrumentation                      =on    #    on
performance_schema_consumer_events_stages_current                      =on    #    off
performance_schema_consumer_events_stages_history                      =on    #    off
performance_schema_consumer_events_stages_history_long                  =off  #    off
performance_schema_consumer_statements_digest                          =on    #    on
performance_schema_consumer_events_statements_current                  =on    #    on
performance_schema_consumer_events_statements_history                  =on    #    on
performance_schema_consumer_events_statements_history_long              =off  #    off
performance_schema_consumer_events_waits_current                        =on    #    off
performance_schema_consumer_events_waits_history                        =on    #    off
performance_schema_consumer_events_waits_history_long                  =off  #    off
performance-schema-instrument                                          ='memory/%=COUNTED'
EOF
    ##config mysql startup script
    cat <<EOF >/etc/init.d/mysql$pt
port=$pt
mysql_user="root"
cmdpath="${data_root}/${pt}/bin"
mysql_sock="${data_root}/${pt}/data/mysql$pt.sock"
#pidname="$(hostname)"
mysqld_pid_file_path="${data_root}/${pt}/data/$(hostname).pid"
start(){
    if [ ! -e "\$mysql_sock" ];then
        printf "Starting MySQL...\n"
        \${cmdpath}/mysqld --defaults-file=/etc/my${pt}.cnf --user=\${mysql_user} 2>/dev/null &
        sleep 3
    else
    printf "MySQL is running...\n"
    exit 1
    fi
}
stop(){
    if [ ! -e "\$mysql_sock" ];then
    printf "MySQL is stopped...\n"
    exit 1
    else
    printf "Stoping MySQL...\n"
    mysqld_pid=\`cat "\$mysqld_pid_file_path"\`
      if (kill -0 \$mysqld_pid 2>/dev/null)
        then
        kill \$mysqld_pid
        sleep 2
      else
        rm \$mysqld_pid_file_path
        fi
    fi
}
restart(){
    printf "Restarting MySQL...\n"
    stop
    sleep 2
    start
}
case "\$1" in
start)
    start
;;
stop)
    stop
;;
restart)
    restart
;;
*)
    printf "Usage: /etc/init.d/mysql${pt} {start|stop|restart}\n"
esac
EOF
    #initial mysqlserver
    ${data_root}/$pt/bin/mysqld --defaults-file=/etc/my$pt.cnf --initialize --basedir=${data_root}/$pt
    #startup mysqlserver
    chmod 755 /etc/init.d/mysql${pt}
    /etc/init.d/mysql${pt} start
    if [ $? -eq 0 ]; then
        sleep 20
        #modify mysqlserver password
        export MYSQL_PWD=$(cat ${data_root}/$pt/data/err.log | grep password | awk -F 'root@localhost:' '{print $NF}' | sed 's/^[][ ]*//g')
        ${data_root}/$pt/bin/mysql --connect-expired-password -hlocalhost -uroot -P${pt} -S ${data_root}/${pt}/data/mysql$pt.sock -e "alter user root@localhost identified by '123123';"
        if [ $? -eq 0 ]; then
            echo "MySQL INSTANCE $pt is install sucessed!"
        else
            echo "MySQL INSTANCE $pt is install maybe failed!please you check"
        fi
    fi
done
