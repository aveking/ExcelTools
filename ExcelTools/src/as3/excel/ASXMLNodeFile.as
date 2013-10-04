package as3.excel
{
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class ASXMLNodeFile
	{
		private var nodeDataMap:Dictionary = new Dictionary();
		
		public function AddNodeDataXML(input:XML, key:String):void{
			var n:NodeDataInfo = nodeDataMap[key];
			if( n != null ){
				var vec:Vector.<XML> = n.nodedata;
				for( var i:int = 0; i < vec.length; i++ ){
					input.appendChild(vec[i]);
				}
			}
		}
		
		public function ASXMLNodeFile(row_list:XMLList, worksheet_name:String, node_name:String):void{			
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
					var addthemapkey:Boolean;
					var isempty_one:Boolean;
					var curwrite_xml:XML = new XML("<"+node_name+"/>");
					var curnode_vec:Vector.<XML> = null;
					for each(cell_node in cell_list)
					{						
						var input_string:String = cell_node.Data;								
						if( cell_index < 1 && "" == input_string ){
							isempty_one = true;
							break;
						}
						
						if( 0 == cell_index){
							curnode_vec = GetNodeDataXML(input_string);
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
												
						if( 1 == cell_index ){
							addthemapkey = true;
						}else{
							if( false == addthemapkey )
								throw worksheet_name;
						}
						
						if(name_strarray[cell_index].thirdnode)
						{
							LinkThirdNode(name_strarray[cell_index].thirdenable, cell_node.Data, curwrite_xml, name_strarray[cell_index].thirdname);
						}else{
							if( input_string != "" )
								curwrite_xml.@[name_strarray[cell_index].params[1]] = input_string;
						}
						
						cell_index++;
					}
					
					if( false == isempty_one ){
						curnode_vec.push(curwrite_xml);
					}

				}	
			}
		}
		
		private function GetNodeDataXML(key:String):Vector.<XML>{
			var n:NodeDataInfo = nodeDataMap[key];
			if( null == n ){
				n = new NodeDataInfo();
				n.key = key;
				n.nodedata = new Vector.<XML>();
				nodeDataMap[key] = n;
			}
			
			return n.nodedata;
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

	}
}


internal class ExcelNameStrInfo{
	public var enable:Boolean;
	public var thirdnode:Boolean;
	public var thirdname:String;
	public var thirdenable:Vector.<ThirdCellInfo> = new Vector.<ThirdCellInfo>();
	public var params:Array;
}

internal class NodeDataInfo{
	public var key:String;
	public var nodedata:Vector.<XML>;
}

internal class ThirdCellInfo{
	public var enable:Boolean;
	public var params:Array;
}