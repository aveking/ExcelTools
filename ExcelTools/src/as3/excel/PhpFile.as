package as3.excel
{
	import com.FileUtil;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class PhpFile
	{
		public function PhpFile(infile:String, outdir:String, filekey:String):void{
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
					info.export_file = outdir + filekey + "_" + curws_name + ".php";
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
						var pnf:PhpNodeFile = new PhpNodeFile(ws.Table.Row, parent_name, child_name, filekey );
						parentfile.nodefiles[curws_name] = pnf;
					}
				}
			}

			for each(var p:PhpOneFileInfo in phpfile_map){
				buildOnePhp( p, filekey );
			}
		}
		
		private function MakePhpDataValue(s:String):String{
			for( var i:int=0; i<s.length; i++){
				if(s.charAt(i)<'0' || s.charAt(i)>'9'){ 
					s = "'"+s+"'";
					break;
				}
			}
			
			return s;
		}
		
		private function getThirdNode(enable_vec:Vector.<Boolean>,strings:String):ByteArray
		{
			var node_ba:ByteArray = new ByteArray();
			node_ba.writeUTFBytes(",array(");
			
			var stringArr:Array = strings.split("；");
			for(var j:int=0;j<stringArr.length;j++)
			{
				var rightchild:Boolean = false;
				var strchild:Array = String(stringArr[j]).split("、");
				for(var i:int =0; i<strchild.length; i++)
				{
					var value:String = strchild[i];
					if( "" == value && i == 0 ){
						break;
					}
					
					if( i > 0 && enable_vec[i] == false )
						continue;
					
					value =	MakePhpDataValue(value);
					if( 0 == i ){
						rightchild = true;
						node_ba.writeUTFBytes( value + "=>array(" + value);
					}else{
						node_ba.writeUTFBytes( "," + value);
					}
				}
				
				if( rightchild )
					node_ba.writeUTFBytes( "),");
			}
			
			node_ba.writeUTFBytes( ")");
			return node_ba;
		}
		
		private function buildOnePhp(info:PhpOneFileInfo, filekey:String):void{
			var phpfile:File = new File(info.export_file);
			var outstream:FileStream = new FileStream();
			
			outstream.open( phpfile, FileMode.WRITE );
			outstream.writeUTFBytes("<?php ");
			
			var pnf:PhpNodeFile;
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
					var cellhead_name:String = filekey + "_" + worksheet_name + "_";
					for each(cell_node in cell_list)
					{
						var namestr_info:ExcelNameStrInfo = new ExcelNameStrInfo();						
						if(String(cell_node.Data).substr(0,4) != "node")
						{
							var cellinfo:Array = String(cell_node.Data).split(" ");
							if( cellinfo[2] == null || cellinfo[2] == "s" ){
								outstream.writeUTFBytes("define('" + cellhead_name + cellinfo[1] + "', " + first_index + ");\n");
								first_index++;
								namestr_info.enable = true;
								namestr_info.params = cellinfo;
							}
						}
						else
						{
							var node_arr:Array = String(cell_node.Data).split("|");
							var node_one:Array = String(node_arr[0]).split(" ");
							if( node_one[2] == null || node_one[2] == "s" ){
								outstream.writeUTFBytes("define('" + cellhead_name + node_one[1] + "', " + first_index + ");\n");
								first_index++;
								namestr_info.enable = true;
								namestr_info.thirdnode = true;
								namestr_info.params = node_arr;
								
								var second_index:int = 0;
								var cell_child_headname:String = cellhead_name + node_one[1] + "_";
								for(i=1; i < node_arr.length; i++){
									node_one = String(node_arr[i]).split(" ");
									if( node_one[2] == null || node_one[2] == "s" ){
										outstream.writeUTFBytes("define('" + cell_child_headname + node_one[1] + "', " + second_index + ");\n");
										namestr_info.thirdenable[i-1] = true;
										second_index++;
									}else{
										namestr_info.thirdenable[i-1] = false;
									}
								}
							}
						}
						
						name_strarray.push(namestr_info);
						cell_index++;
					}
					
					for each(pnf in info.nodefiles){
						pnf.AddNodeHeadDefine( outstream, cell_index );
						cell_index++;
					}

					outstream.writeUTFBytes("return array(");
				}
				else
				{
					cell_index = 0;
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
								
								outstream.writeUTFBytes( ",0");
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

						input_string = MakePhpDataValue(input_string);
						
						if( 0 == cell_index ){
							node_keyname = input_string;
							outstream.writeUTFBytes( input_string + "=>array(");
							addthemapkey = true;
						}else{
							if( false == addthemapkey )
								throw worksheet_name;
						}
						
						if(name_strarray[cell_index].thirdnode)
						{
							outstream.writeBytes( getThirdNode(name_strarray[cell_index].thirdenable, cell_node.Data) );				
						}else{
							if( 0 == cell_index ){
								outstream.writeUTFBytes( input_string );
							}else{
								outstream.writeUTFBytes( "," + input_string );
							}
						}
						
						cell_index++;
					}
					
					if( false == isempty_one ){
						for(;cell_index < name_strarray.length; cell_index++){
							if(name_strarray[cell_index].enable == false)
								continue;
							
							outstream.writeUTFBytes(",0");
						}
						
						for each(pnf in info.nodefiles){
							pnf.AddNodeData( outstream, node_keyname );
							cell_index++;
						}
						
						outstream.writeUTFBytes( "),\n");
					}
				}	
			}

			outstream.writeUTFBytes("); ?>");
			outstream.close();
		}
	}
}
import flash.utils.Dictionary;

internal class PhpOneFileInfo{
	public var worksheet:String;
	public var export_file:String;
	public var exceldata:XML;
	public var nodefiles:Dictionary = new Dictionary();
}

internal class ExcelNameStrInfo{
	public var enable:Boolean;
	public var thirdnode:Boolean;
	public var thirdenable:Vector.<Boolean> = new Vector.<Boolean>();
	public var params:Array;
}