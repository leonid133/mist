package io.hydrosphere.mist.master

import java.util.UUID

import akka.actor.{ActorSystem, Props}
import akka.testkit.{ImplicitSender, TestActorRef, TestKit, TestProbe}
import io.hydrosphere.mist.jobs.store.InMemoryJobRepository
import io.hydrosphere.mist.jobs.{FullJobConfigurationBuilder, JobDetails}
import io.hydrosphere.mist.master.JobManager.StartJob
import io.hydrosphere.mist.master.JobQueue.{DequeueJob, EnqueueJob}
import org.scalatest._

class JobQueueTest extends TestKit(ActorSystem("mist-tests")) with ImplicitSender with FunSpecLike with Matchers {
  
  private def job() = {
    val jobConfiguration = FullJobConfigurationBuilder()
      .fromRouter("simple-context", Map.empty[String, Any], None)
      .build()
    JobDetails(jobConfiguration, JobDetails.Source.Cli, UUID.randomUUID().toString)
  }

  private val runningJob = job()
  private val queuedJob = job()

  private val store = new InMemoryJobRepository()
  
  describe("Job Queue") {
    
    it("should start enqueued job") {
      val probe = TestProbe()
      val actorRef = TestActorRef(Props(classOf[JobQueue], probe.ref, store))

      store.update(runningJob)
      actorRef ! EnqueueJob(runningJob)
      probe.expectMsg(StartJob(runningJob))
      store.get(runningJob.jobId).map(_.status).get shouldBe JobDetails.Status.Running
    }

    val probe = TestProbe()
    val actorRef = TestActorRef(Props(classOf[JobQueue], probe.ref, store))

    it("should not start jobs if queue is full") {
      store.update(queuedJob)
      actorRef ! EnqueueJob(queuedJob)
      probe.expectNoMsg()
      store.get(queuedJob.jobId).map(_.status).get shouldBe JobDetails.Status.Queued
    }
    
    it("should start jobs when queue is released") {
      val stoppedJob = runningJob.withStatus(JobDetails.Status.Stopped)
      store.update(stoppedJob)
      actorRef ! DequeueJob(stoppedJob)
      probe.expectMsg(StartJob(queuedJob))
      store.get(queuedJob.jobId).map(_.status).get shouldBe JobDetails.Status.Running
    }
    
  }
}