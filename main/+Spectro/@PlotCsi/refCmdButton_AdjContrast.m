function refCmdButton_AdjContrast(obj,hObject,eventdata,refdx)

if strcmp(get(obj.misc.panes(refdx).refMenu.adjContrast,'checked'),'off')
   set(obj.misc.panes(refdx).refMenu.adjContrast,'checked','on');
   set(obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'visible','on') 
   set(obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'visible','on') 

elseif strcmp(get(obj.misc.panes(refdx).refMenu.adjContrast,'checked'),'on')
    set(obj.misc.panes(refdx).refMenu.adjContrast,'checked','off');
    set(obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'visible','off')
    set(obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'visible','off')

    
end


   


