package com.uqee.xajh.editor
{
	import flash.filesystem.File;
	public interface IEditor
	{
		function init():void;
		function save(dir:File):void;
		function load(dir:File):void;
	}
}