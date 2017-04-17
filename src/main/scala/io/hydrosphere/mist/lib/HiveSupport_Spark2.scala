package io.hydrosphere.mist.lib
import io.hydrosphere.mist.contexts.ContextWrapper
import org.apache.spark.sql.SparkSession

trait HiveSupport extends SessionSupport {

  private var _session: SparkSession = _

  override def session: SparkSession = _session

  override private[mist] def setup(sc: ContextWrapper): Unit = {
    super.setup(sc)
    sc.withHive()
    _session = sc.sparkSession
  }

}
