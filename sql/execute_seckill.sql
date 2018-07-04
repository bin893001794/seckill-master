-- 秒杀执行储存过程
DELIMITER $$ -- 将定界符从;转换为$$
-- 定义储存过程
-- 参数： in输入参数   out输出参数
-- row_count() 返回上一条修改类型sql(delete,insert,update)的影响行数
-- row_count:0:未修改数据 ; >0:表示修改的行数； <0:sql错误
CREATE PROCEDURE `seckill`.`execute_seckill`
  (IN v_seckill_id BIGINT, IN v_phone BIGINT,
   IN v_kill_time  TIMESTAMP, OUT r_result INT) --创建一个传4个参数的存储过程，参数：in输入参数，OUT输出参数（返回出去的数）
  BEGIN  --开始存储过程
    DECLARE insert_count INT DEFAULT 0; -- 声明一个insert_count（返回上一条修改类型sql的影响行数（delete,insert,update）变量并赋值
    START TRANSACTION; -- 启动一个事务
    INSERT IGNORE INTO success_killed(seckill_id, user_phone, state)VALUES (v_seckill_id, v_phone, 0); --“insert ignore" 当有重复记录就会忽略,执行后返回数字0
    SELECT row_count() INTO insert_count;--row_count返回上一行insert影响的行数并且赋给insert_count；0；标示未修改数据，>0：标示修改的行数，<0 标示sql错误/执行修改
    IF (insert_count = 0) THEN --没有插入处理数据
      ROLLBACK; -- 回滚
      SET r_result = -1;  -- 赋值r_result=-1
    ELSEIF (insert_count < 0) THEN --插入处理异常
	ROLLBACK; -- 回滚
	SET r_result = -2; -- 赋值r_result=-2
    ELSE --否则（插入处理成功，秒杀成功）
      UPDATE seckill SET number = number - 1 WHERE seckill_id = v_seckill_id AND end_time > v_kill_time AND start_time < v_kill_time AND number > 0; --更秒杀表的剩余数，没秒杀成功一次就数量递减1
      SELECT row_count() INTO insert_count; --row_count返回上一行UPDATE影响的行数并且赋给insert_count；0；标示未修改数据，>0：标示修改的行数，<0 标示sql错误/执行修改
      IF (insert_count = 0) THEN --没有修改数据
	ROLLBACK;-- 回滚
	SET r_result = 0;-- 赋值r_result=-0
      ELSEIF (insert_count < 0) THEN--修改处理异常
	  ROLLBACK;-- 回滚
	  SET r_result = -2;-- 赋值r_result=-2
      ELSE--否则（修改处理成功，秒杀成功）
	COMMIT;--提交事务
	SET r_result = 1; --赋值r_result=1
      END IF;
    END IF;
  END;
$$
-- 储存过程定义结束
-- 将定界符重新改为;
DELIMITER ;

-- 定义一个用户变量r_result
SET @r_result = -3;
-- 执行储存过程
CALL execute_seckill(1003, 13502178891, now(), @r_result);
-- 获取结果
SELECT @r_result;