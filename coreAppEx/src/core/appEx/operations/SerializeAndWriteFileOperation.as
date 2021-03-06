// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

package core.appEx.operations
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import core.app.core.managers.fileSystemProviders.IFileSystemProvider;
	import core.app.core.managers.fileSystemProviders.operations.IWriteFileOperation;
	import core.app.core.operations.IAsynchronousOperation;
	import core.app.core.serialization.ISerializationPlugin;
	import core.app.entities.URI;
	import core.app.events.OperationProgressEvent;
	import core.app.operations.SerializeOperation;

	public class SerializeAndWriteFileOperation extends EventDispatcher implements IAsynchronousOperation
	{
		private var item				:*;
		private var _uri				:URI;
		private var fileSystemProvider	:IFileSystemProvider;
		private var plugins				:Vector.<ISerializationPlugin>;
		
		private var serializeOperation	:SerializeOperation;
		private var writeFileOperation	:IWriteFileOperation;
		
		public function SerializeAndWriteFileOperation( item:*, uri:URI, fileSystemProvider:IFileSystemProvider, plugins:Vector.<ISerializationPlugin> = null )
		{
			this.item = item;
			_uri = uri;
			this.fileSystemProvider = fileSystemProvider;
			this.plugins = plugins;
		}
		
		public function execute():void
		{
			serializeOperation = new SerializeOperation( item, plugins );
			serializeOperation.addEventListener( Event.COMPLETE, serializeCompleteHandler );
			serializeOperation.addEventListener(OperationProgressEvent.PROGRESS, progressHandler);
			serializeOperation.addEventListener(ErrorEvent.ERROR, errorHandler);
			serializeOperation.execute();
		}
		
		private function serializeCompleteHandler( event:Event ):void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes( serializeOperation.getResult().toXMLString() );
			
			writeFileOperation = fileSystemProvider.writeFile(_uri, bytes);
			writeFileOperation.addEventListener(Event.COMPLETE, writeFileCompleteHandler);
			writeFileOperation.addEventListener(OperationProgressEvent.PROGRESS, progressHandler);
			writeFileOperation.addEventListener(ErrorEvent.ERROR, errorHandler);
			writeFileOperation.execute();
		}
		
		private function progressHandler( event:OperationProgressEvent ):void
		{
			if ( !writeFileOperation )
			{
				dispatchEvent( new OperationProgressEvent( OperationProgressEvent.PROGRESS, event.progress * 0.5 ) );
			}
			else
			{
				dispatchEvent( new OperationProgressEvent( OperationProgressEvent.PROGRESS, 0.5 + (event.progress * 0.5) ) );
			}
		}
		
		private function errorHandler( event:ErrorEvent ):void
		{
			dispatchEvent( event.clone() );
		}
		
		private function writeFileCompleteHandler( event:Event ):void
		{
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		public function get uri():URI { return _uri; }
		
		public function get label():String { return "Serialize and write file : " + _uri.getFilename(); }
	}
}