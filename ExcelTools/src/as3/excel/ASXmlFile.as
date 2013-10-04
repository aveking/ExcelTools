package as3.excel
{
	import com.FileUtil;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class ASXmlFile
	{
		public function ASXmlFile(infile:String, outdir:String, filename:String):void{
			var root_xml:XML = new XML("<"+filename+"list/>")
				
			var phpfile_map:Dictionary = new Dictionary();
			var workSheetList:XMLList = FileUtil.LoadExcelXmlFile(infile);
			
			var lastlist_name:String = "";
			var curws_name:String;
			var ws:XML;
			for each(ws in workSheetList){
				curws_name = ws.@ssName;
				if(curws_name.search("_node_") > 0){
					
				}else{
					var info:PhpOneFileInfo = new PhpOneFileInfo();
					info.worksheet = curws_name;
					info.exceldata = ws;
					phpfile_map[curws_name] = info;
				}
			}
			
			for each(ws in workSheetList){
				curws_name = ws.@ssName;
				var node_pos:int = curws_name.search("_node_");
				if(node_pos > 0){
					var parent_name:String = curws_name.substr( 0, node_pos );
					var child_name:String = curws_name.substr( node_pos + 6 );
					
					var parentfile:PhpOneFileInfo = phpfile_map[parent_name];
					if( parentfile != null ){
						var axnf:ASXMLNodeFile = new ASXMLNodeFile(ws.Table.Row, parent_name, child_name);
						parentfile.nodefiles[curws_name] = axnf;
					}
				}
			}
			
			for each(var p:PhpOneFileInfo in phpfile_map){
				BuildOneXmlList( p, root_xml );
			}

			var file:File = new File(outdir + filename + ".xml");
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(root_xml.toXMLString());
			fs.close();
		}
				
		private function LinkThirdNode(enable_vec:Vector.<ThirdCellInfo>, strings:String, parentxml:XML, thirdname:String):void
		{
			var stringArr:Array = strings.split("；");
			for(var j:int=0;j<stringArr.length;j++)
			{
				var thirdxml:XML = new XML("<"+thirdname+"/>");
				var rightchild:Boolean = false;
				var strchild:Array = String(stringArr[j]).split("、");
				for(var i:int =0; i<strchild.length; i++)
				{
					var value:String = strchild[i];
					if( "" == value && i == 0 ){
						break;
					}
					
					if( i > 0 && enable_vec[i].enable == false )
						continue;
					
					rightchild = true;
					
					thirdxml.@[enable_vec[i].params[1]] = value;
				}
				
				if( rightchild )
					parentxml.appendChild(thirdxml);
			}
		}
		
		private function BuildOneXmlList(info:PhpOneFileInfo, root:XML):void{
			var axnf:ASXMLNodeFile;
			var i:int;
			var worksheet_name:String = info.worksheet;
			var row_node:XML;
			var row_list:XMLList = info.exceldata.Table.Row;
			var row_index:int = 0;
			var cell_index:int = 0;
			var cell_node:XML;
			var cell_list:XMLList;
			var name_strarray:Vector.<ExcelNameStrInfo> = new Vector.<ExcelNameStrInfo>;
			
			for each(row_node in row_list)
			{
				cell_index=0;
				row_index++;
				if(row_index==1)
					continue;
				
				cell_list = row_node.Cell;
				if(row_index==2)
				{
					var first_index:int;
					for each(cell_node in cell_list)
					{
						var namestr_info:ExcelNameStrInfo = new ExcelNameStrInfo();						
						if(String(cell_node.Data).substr(0,4) != "node")
						{
							var cellinfo:Array = String(cell_node.Data).split(" ");
							if( cellinfo[2] == null || cellinfo[2] == "c" ){
								first_index++;
								namestr_info.enable = true;
								namestr_info.params = cellinfo;
							}
						}
						else
						{
							var node_arr:Array = String(cell_node.Data).split("|");
							var node_one:Array = String(node_arr[0]).split(" ");
							if( node_one[2] == null || node_one[2] == "c" ){
								first_index++;
								namestr_info.enable = true;
								namestr_info.thirdnode = true;
								namestr_info.thirdname = node_one[1];
								namestr_info.params = node_arr;
								
								var second_index:int = 0;
								for(i=1; i < node_arr.length; i++){
									var tci:ThirdCellInfo = new ThirdCellInfo();
									node_one = String(node_arr[i]).split(" ");
									if( node_one[2] == null || node_one[2] == "c" ){
										tci.enable = true;
										second_index++;
									}else{
										tci.enable = false;
									}
									
									tci.params = node_one;
									namestr_info.thirdenable[i-1] = tci;
								}
							}
						}
						
						name_strarray.push(namestr_info);
						cell_index++;
					}
				}
				else
				{
					cell_index = 0;
					var addcellxml:XML = new XML("<"+worksheet_name+"/>");
					var addthemapkey:Boolean;
					var isempty_one:Boolean;
					var node_keyname:String;
					for each(cell_node in cell_list)
					{						
						var input_string:String = cell_node.Data;								
						if( 0 == cell_index && "" == input_string ){
							isempty_one = true;
							break;
						}
						
						//填充空位
						if(cell_node.@ssIndex != undefined){
							var curpos:int = cell_node.@ssIndex-1;
							for(;cell_index < curpos; cell_index++){
								if(cell_index>=name_strarray.length)
									continue;
								
								if(name_strarray[cell_index].enable == false)
									continue;
							}
						}
						
						if(cell_index>=name_strarray.length)
							continue;
						
						if(!name_strarray[cell_index])
							throw "php171";
						
						if(name_strarray[cell_index].enable == false){
							cell_index++;
							continue;
						}

						if( 0 == cell_index ){
							node_keyname = input_string;
							addthemapkey = true;
						}else{
							if( false == addthemapkey )
								throw worksheet_name;
						}
						
						if(name_strarray[cell_index].thirdnode)
						{
							LinkThirdNode(name_strarray[cell_index].thirdenable, cell_node.Data, addcellxml, name_strarray[cell_index].thirdname);
						}else{
							if( input_string != "" )
								addcellxml.@[name_strarray[cell_index].params[1]] = input_string;
						}
						
						cell_index++;
					}
					
					if( false == isempty_one ){
						for each(axnf in info.nodefiles){
							axnf.AddNodeDataXML(addcellxml, node_keyname);
							cell_index++;
						}

						root.appendChild(addcellxml);
					}
				}	
			}
		}
	}
}


import flash.utils.Dictionary;

internal class PhpOneFileInfo{
	public var worksheet:String;
	public var exceldata:XML;
	public var nodefiles:Dictionary = new Dictionary();
}

internal class ExcelNameStrInfo{
	public var enable:Boolean;
	public var thirdnode:Boolean;
	public var thirdname:String;
	public var thirdenable:Vector.<ThirdCellInfo> = new Vector.<ThirdCellInfo>();
	public var params:Array;
}

internal class ThirdCellInfo{
	public var enable:Boolean;
	public var params:Array;
}