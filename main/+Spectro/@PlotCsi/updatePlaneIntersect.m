function updatePlaneIntersect(obj)

for refdx=1:numel(obj.misc.panes)
    for refdxOther=1:numel(obj.misc.panes)
        if refdx ~= refdxOther
            if obj.showSliceLines
                % Use try..catch in case two reference images are parallel (and
                % thus there is no line of intersection).
                
                try
                    set(obj.misc.panes(refdx).hIntersectLines{refdxOther},...
                        'Visible','on',...
                        'Color',obj.misc.axisColours.inactive(refdxOther,:));
                    
                    set(obj.misc.panes(refdx).hIntersectLines{refdxOther}(obj.misc.panes(refdxOther).nSlice),...
                        'Color',obj.misc.axisColours.active(refdxOther,:));
                catch
                end
            else
                try
                    set(obj.misc.panes(refdx).hIntersectLines{refdxOther},'Visible','off');
                catch
                end
            end
        end
    end
end
