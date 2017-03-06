package io.hydrosphere.mist.jobs.store

import io.hydrosphere.mist.MistConfig
import io.hydrosphere.mist.jobs.JobDetails
import io.hydrosphere.mist.jobs.JobDetails.Status
import io.hydrosphere.mist.utils.Logger
import org.mapdb.{DBMaker, Serializer}
import io.hydrosphere.mist.utils.json.JobDetailsJsonSerialization
import spray.json._

private[mist] class MapDbJobRepository(filePath: String) extends JobRepository
  with JobDetailsJsonSerialization with Logger {
  // Db
  private lazy val db = DBMaker
    .fileDB(filePath)
    .fileLockDisable
    .closeOnJvmShutdown
    .checksumHeaderBypass()
    .make

  // Map
  private lazy val map = db
    .hashMap("map", Serializer.STRING, Serializer.BYTE_ARRAY)
    .createOrOpen
  
  private def add(jobDetails: JobDetails): Unit = {
    map.put(jobDetails.jobId, serialize(jobDetails))
    logger.info(s"${jobDetails.jobId} saved in MapDb")
  }

  override def remove(jobId: String): Unit = {
    map.remove(jobId)
    logger.info(s"$jobId removed from MapDb")
  }

  private def getAll: List[JobDetails] = {
    map.getKeys.toArray().toList.flatMap(key => get(key.toString))
  }

  override def get(jobId: String): Option[JobDetails] = {
    Option(map.get(jobId)).map(deserialize)
  }

  override def size: Long = {
    map.getSize
  }

 override def clear(): Unit = {
   map.clear()
 }

  override def update(jobDetails: JobDetails): Unit = {
    add(jobDetails)
  }

  override def filteredByStatuses(statuses: List[Status]): List[JobDetails] = {
    getAll.filter {
      job: JobDetails => statuses contains job.status
    }
  }

  private def serialize(jobDetails: JobDetails): Array[Byte] =
    jobDetails.toJson.compactPrint.getBytes

  private def deserialize(bytes: Array[Byte]): JobDetails =
    new String(bytes).parseJson.convertTo[JobDetails]
}

object MapDbJobRepository extends MapDbJobRepository(MistConfig.History.filePath)
