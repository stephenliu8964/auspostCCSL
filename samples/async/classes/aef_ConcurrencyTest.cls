/**
 * This ensure no concurrency errors are reached for long running transactions
 */
public with sharing class aef_ConcurrencyTest {

	public static void play() {

		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(new List<SObjectType>{
				Account.SObjectType, Contact.SObjectType
		});

		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));

		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));

		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));

		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));
		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerConcurrencyTest.class));

		// normally this would be handled automatically with the trigger framework
		uow.commitWork();

	}

	public class AsyncWorkerConcurrencyTest extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override Type getClassType() {
			return AsyncWorkerConcurrencyTest.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return null;
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			for(Integer i=0;i<5000000;i++) {
				System.debug('Do nothing');
			}

		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

}