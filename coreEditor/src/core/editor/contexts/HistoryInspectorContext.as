// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package core.editor.contexts
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import core.ui.components.List;
	import core.data.ArrayCollection;
	import core.ui.events.ListEvent;
	
	import core.editor.CoreEditor;
	import core.appEx.core.contexts.IOperationManagerContext;
	import core.appEx.core.contexts.IVisualContext;
	import core.app.core.operations.IOperation;
	import core.appEx.events.OperationManagerEvent;
	import core.app.events.ValidatorEvent;
	import core.appEx.managers.OperationManager;
	import core.appEx.validators.ContextValidator;

	public class HistoryInspectorContext implements IVisualContext
	{
		protected var _historyManager		:OperationManager;
		protected var contextValidator		:ContextValidator;
		
		protected var _view					:List;
		
		public function HistoryInspectorContext()
		{
			_view = new List();
			_view.padding = 0;
			_view.showBorder = false;
			
			contextValidator = new ContextValidator( CoreEditor.contextManager, IOperationManagerContext, false );
			contextValidator.addEventListener( ValidatorEvent.STATE_CHANGED, refresh );
			refresh();
			//_view.addEventListener( Event.CHANGE, listChangeHandler );
			_view.addEventListener(ListEvent.ITEM_SELECT, listSelectHandler);
		}
				
		public function dispose():void
		{
			//_view.removeEventListener( Event.CHANGE, listChangeHandler );
			_view.removeEventListener(ListEvent.ITEM_SELECT, listSelectHandler);
			
			historyManager = null;
			contextValidator.removeEventListener( ValidatorEvent.STATE_CHANGED, refresh );
			contextValidator.dispose();
			contextValidator = null;
		}
		
		public function get view():DisplayObject { return _view; }
		
		protected function listSelectHandler( event:ListEvent ):void
		{
			if ( contextValidator.state == false ) return;
			var context:IOperationManagerContext = IOperationManagerContext( contextValidator.getContext() );
			
			var selectedItem:Object = _view.selectedItems[0];
			var index:int = ArrayCollection(_view.dataProvider).source.indexOf(selectedItem);
			context.operationManager.gotoOperation( index );
		}
		
		protected function operationManagerChangeHandler( event:OperationManagerEvent ):void
		{
			updateList()
		}
		
		protected function set historyManager(value:OperationManager):void
		{
			if ( _historyManager ) 
			{
				_historyManager.removeEventListener( OperationManagerEvent.CHANGE, operationManagerChangeHandler );
			}
			_historyManager = value;
			if ( _historyManager ) 
			{
				_historyManager.addEventListener( OperationManagerEvent.CHANGE, operationManagerChangeHandler );
			}
		}
		protected function get historyManager():OperationManager { return _historyManager }
		
		protected function refresh( event:Event = null ):void
		{
			if ( contextValidator.state )
			{
				historyManager = IOperationManagerContext( contextValidator.getContext() ).operationManager;
				updateList();
			}
			else
			{
				historyManager = null;
				_view.dataProvider = new ArrayCollection();
			}
		}
		
		protected function updateList():void
		{
			var operations:Vector.<IOperation> = _historyManager.getOperations();
			var dp:ArrayCollection = new ArrayCollection();
			for ( var i:int = 0; i < operations.length; i++ )
			{
				var operation:IOperation = operations[i];
				dp.addItem( operation );
			}
			
			_view.dataProvider = dp;
			_view.selectedItems = [_historyManager.currentOperation];
			
			if ( dp.length > 0 ) 
			{
				_view.scrollToItem( _view.selectedItem );
			}
		}
	}
}