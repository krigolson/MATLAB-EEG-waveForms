function wf_save_png(fig, imageFile)
%WF_SAVE_PNG Save figures with a renderer that avoids line dropout artifacts.

try
    set(fig, 'Renderer', 'painters');
catch
end

if exist('exportgraphics', 'file') == 2
    try
        exportgraphics(fig, imageFile, 'Resolution', 200);
        return;
    catch
    end
end

try
    print(fig, imageFile, '-dpng', '-r200', '-painters');
catch
    print(fig, imageFile, '-dpng', '-r200');
end
end
