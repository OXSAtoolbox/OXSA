function plotCSI_contrastCallback(obj,hObject,eventdata,refdx)

 valA = double(obj.misc.panes(refdx).contrast_spinnerA.jhSpinner.getValue());
 valB = double(obj.misc.panes(refdx).contrast_spinnerB.jhSpinner.getValue());
            
 % Originally plotted with
 %h.hFigImage = subimage(h.current.img,valA+[-0.5 0.5]*valB);
 % But if we call that again we'll duplicate the image object.
 
 clim = valA+[-0.5 0.5]*valB;
 
 cdata = obj.data.imgRef{refdx};
 
 cdata = cellfun(@(x) double(cat(3, x, x, x)),cdata,'UniformOutput',false);
 cdata = cellfun(@(x) (x - clim(1)) / (clim(2) - clim(1)),cdata,'UniformOutput',false);
 cdata = cellfun(@(x) min(max(x,0),1),cdata,'UniformOutput',false);
 
 cellfun(@(x,y) set(obj.misc.panes(refdx).hImages(y),'CData',x),cdata,num2cell(1:numel(cdata)).');