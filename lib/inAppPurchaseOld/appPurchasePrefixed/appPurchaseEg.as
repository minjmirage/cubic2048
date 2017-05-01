import com.adobe.nativeExtensions.AppPurchase;
import com.adobe.nativeExtensions.AppPurchaseEvent;
import com.adobe.nativeExtensions.Product;
import com.adobe.nativeExtensions.Transaction;


import mx.collections.ArrayCollection;
import mx.events.FlexEvent;
import mx.messaging.Producer;


import spark.events.IndexChangeEvent;
[Bindable] var arrC = null;
protected function application1_applicationCompleteHandler(event:FlexEvent):void
{
	AppPurchase.manager.addEventListener(AppPurchaseEvent.UPDATED_TRANSACTIONS,onUpdate);
	AppPurchase.manager.addEventListener(AppPurchaseEvent.RESTORE_FAILED,function(e:AppPurchaseEvent):void
	{
		trace(e.error);
	});
	AppPurchase.manager.addEventListener(AppPurchaseEvent.RESTORE_COMPLETE,function(e:AppPurchaseEvent):void
	{
		trace("Restore COMPLETE");
	});
	AppPurchase.manager.addEventListener(AppPurchaseEvent.REMOVED_TRANSACTIONS,function(e:AppPurchaseEvent):void
	{
		for each(var t:Transaction in e.transactions)
		{
			trace ("Removed: " + t.transactionIdentifier);
		}
	});

	AppPurchase.manager.restoreTransactions();  // Restore previous successful transactions. Results in UPDATE events

	var ts:Array = AppPurchase.manager.transactions;
	for each(var t:Transaction in ts)
	{
		// Iterate over in-Que transactions
	}

	trace ("APP - MUTED " + AppPurchase.manager.muted);  // Check if App Store payments are restricted.
}//endfunction

//=============================================================================
//
//=============================================================================
protected function button1_clickHandler(event:MouseEvent):void
{
	AppPurchase.manager.addEventListener(AppPurchaseEvent.PRODUCTS_RECEIVED,onProducts);
	AppPurchase.manager.getProducts(["suite","pepsi","ball"]); // Get the Products info from iTunes Connect.
															   // (For the ones that you have defined)
}//endfunction

//=============================================================================
//
//=============================================================================
protected function onProducts(e:AppPurchaseEvent):void
{
	arrC = new ArrayCollection(e.products); // Products received populate the list
	for each(var s:String in e.invalidIdentifiers)
	{ // List of ids for which products could not be retrieved.
		trace(s);
	}
}//endfunction

//=============================================================================
//
//=============================================================================
protected function onUpdate(e:AppPurchaseEvent):void
{
	trace("APP - onUpdate");
	for each(var t:Transaction in e.transactions)
	{ // Iterate over transactions whose status changed
		if(t.state == Transaction.TRANSACTION_STATE_PUCHASED)
		{
			// Verify that this receipt came from apple and is not forged
			 var req:URLRequest = new URLRequest("https://sandbox.itunes.apple.com/verifyReceipt");
			req.method = URLRequestMethod.POST;
			req.data = "{\"receipt-data\" : \""+ t.receipt +"\"}";
			var ldr:URLLoader = new URLLoader(req);
			ldr.load(req);
			ldr.addEventListener(Event.COMPLETE,function(e:Event):void
			{
				trace("LOAD COMPLETE: " + ldr.data); // status property in retrieved JSON is 0 then success
				// Provide the purchased functionality/service/product/subscription to user.
				AppPurchase.manager.finishTransaction(t.transactionIdentifier); // Finish the transaction completely
			});
		}
		else if(t.state == Transaction.TRANSACTION_STATE_RESTORED)
		{
			// Useful for restoring Non-Consumable purchases made by user. Read programming guide for more details.
			if(t.originalTransaction.state == Transaction.TRANSACTION_STATE_PUCHASED)
			{
				AppPurchase.manager.finishTransaction(t.originalTransaction.transactionIdentifier);
				trace("Restored Transaction Finish on " + t.transactionIdentifier);
			}
		}
	}
}//endfunction

//=============================================================================
//
//=============================================================================
protected function list1_changeHandler(event:IndexChangeEvent):void
{
	var p:Product = arrC[event.newIndex] as Product;
	AppPurchase.manager.startPayment(p.identifier,1); // Purchase 1 quantity of the selected product.
}//endfunction

