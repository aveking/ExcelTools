package com.uqee.xajh
{
	import com.uqee.xajh.editor.XMLFileUtil;
	
	import flash.filesystem.File;
	import flash.utils.Dictionary;

	public class XMLManager
	{
		private var cache_:Dictionary;
		private static var instance_:XMLManager;
		public function XMLManager()
		{
			cache_ = new Dictionary();
		}
		
		public static function get instance():XMLManager {
			if (!instance_) {
				instance_ = new XMLManager();
			}
			return instance_;
		}
		
		public function loadXML(filename:String):void {		
			var xml:XML = XMLFileUtil.getXML(File.applicationDirectory.nativePath + "/" + filename);
			if (xml) {
				cache_[filename] = xml;
			}
		}
		
		public function getXML(name:String):XML {
			return cache_[name];
		}
	}
}