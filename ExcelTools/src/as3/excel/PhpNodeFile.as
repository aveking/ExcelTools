package as3.excel
{
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class PhpNodeFile
	{
		private var headParentIndexStr:String;
		private var headDefineInfo:ByteArray = new ByteArray();
		private var nodeDataMap:Dictionary = new Dictionary();
		
		public function AddNodeHeadDefine(input:FileStream, index:int):void{
			input.writeUTFBytes("define('" + headParentIndexStr + "', " + index + ");\n");
			input.writeBytes(headDefineInfo);
		}
		
		public function AddNodeData(input:FileStream, key:String):void{
			var n:NodeDataInfo = nodeDataMap[key];
			if( n != null && n.nodedata.length > 10 ){
				input.writeBytes(n.nodedata);
			}else{
				input.writeUTFBytes(",0");
			}
		}
		
		public function PhpNodeFile(row_list:XMLList, worksheet_name:String, node_name:String, filekey:String):void{			
			var i:int;
			var row_node:XML;
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
					cell_index = 0;
					var first_index:int;
					headParentIndexStr = filekey + "_" + worksheet_name + "_" + node_name;
					var cellhead_name:String = filekey + "_" + worksheet_name + "_" + node_name + "_";
					for each(cell_node in cell_list)
					{
						var namestr_info:ExcelNameStrInfo = new ExcelNameStrInfo();						
						if( cell_index < 1 )
						{
							name_strarray.push(namestr_info);
							cell_index++;
							continue;
						}
						
						if(String(cell_node.Data).substr(0,4) != "node")
						{
							var cellinfo:Array = String(cell_node.Data).split(" ");
							if( cellinfo[2] == null || cellinfo[2] == "s" ){
								headDefineInfo.writeUTFBytes("define('" + cellhead_name + cellinfo[1] + "', " + first_index + ");\n");
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
								headDefineInfo.writeUTFBytes("define('" + cellhead_name + node_one[1] + "', " + first_index + ");\n");
								first_index++;
								namestr_info.enable = true;
								namestr_info.thirdnode = true;
								namestr_info.params = node_arr;
								
								var second_index:int = 0;
								var cell_child_headname:String = cellhead_name + node_one[1] + "_";
								for(i=1; i < node_arr.length; i++){
									node_one = String(node_arr[i]).split(" ");
									if( node_one[2] == null || node_one[2] == "s" ){
										headDefineInfo.writeUTFBytes("define('" + cell_child_headname + node_one[1] + "', " + second_index + ");\n");
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
				}
				else
				{
					cell_index = 0;
					var addthemapkey:Boolean;
					var isempty_one:Boolean;
					var curwriteba:ByteArray = null;
					for each(cell_node in cell_list)
					{						
						var input_string:String = cell_node.Data;								
						if( cell_index < 1 && "" == input_string ){
							isempty_one = true;
							break;
						}
						
						if( 0 == cell_index){
							curwriteba = GetNodeDataBA(input_string);
							cell_index++;
							continue;
						}
						
						//填充空位
						if(cell_node.@ssIndex != undefined){
							var curpos:int = cell_node.@ssIndex-1;
							for(;cell_index < curpos; cell_index++){
								if(cell_index>=name_strarray.length)
									continue;
								
								if(name_strarray[cell_index].enable == false)
									continue;
								
								curwriteba.writeUTFBytes( ",0");
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
						
						if( 1 == cell_index ){
							curwriteba.writeUTFBytes( input_string + "=>array(");
							addthemapkey = true;
						}else{
							if( false == addthemapkey )
								throw worksheet_name;
						}
						
						if(name_strarray[cell_index].thirdnode)
						{
							curwriteba.writeBytes( getThirdNode(name_strarray[cell_index].thirdenable, cell_node.Data) );				
						}else{
							if( 1 == cell_index ){
								curwriteba.writeUTFBytes( input_string );
							}else{
								curwriteba.writeUTFBytes( "," + input_string );
							}
						}
						
						cell_index++;
					}
					
					if( false == isempty_one ){
						for(;cell_index < name_strarray.length; cell_index++){
							if(name_strarray[cell_index].enable == false)
								continue;
							
							curwriteba.writeUTFBytes( ",0");
						}
						
						curwriteba.writeUTFBytes( "),\n");
					}
				}	
			}

			for each(var ndi:NodeDataInfo in nodeDataMap ){
				ndi.nodedata.writeUTFBytes(")");
				
			}
		}
		
		private function GetNodeDataBA(key:String):ByteArray{
			var n:NodeDataInfo = nodeDataMap[key];
			if( null == n ){
				n = new NodeDataInfo();
				n.key = key;
				n.nodedata = new ByteArray();
				n.nodedata.writeUTFBytes(",array(");
				nodeDataMap[key] = n;
			}
			
			return n.nodedata;
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
	}
}


import flash.utils.ByteArray;

internal class ExcelNameStrInfo{
	public var enable:Boolean;
	public var thirdnode:Boolean;
	public var thirdenable:Vector.<Boolean> = new Vector.<Boolean>();
	public var params:Array;
}

internal class NodeDataInfo{
	public var key:String;
	public var nodedata:ByteArray;
}