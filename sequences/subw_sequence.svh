class subw_sequence extends basic_sequence;

   `uvm_object_utils(subw_sequence);

   function new(string name = "addw");
      super.new(name);
   endfunction : new

   function alu_op get_operator();
	return SUBW;
   endfunction : get_operator

   task body();
      super.body();
   endtask : body
endclass : subw_sequence
