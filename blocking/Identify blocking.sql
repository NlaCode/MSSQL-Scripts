-- Simple understand of blocking w/ whoisactive

EXEC sp_WhoIsActive
@find_block_leaders = 1
--,@get_plans = 1
--,@get_additional_info = 1
--,@get_full_inner_text = 1
--,@get_outer_command = 1
,@sort_order = '[blocked_session_count] DESC'
,@output_column_list = '[dd%][session_id][sql_text][sql_command][block%][status][open_tran_count][host_name][wait_info][login_name][tasks][tran_log%][cpu%][temp%][reads%][writes%][context%][physical%][query_plan][locks][%]'
--,@filter_type = ''
--,@filter = ''
GO
